import firebase_admin
import os
import logging
from firebase_admin import credentials, messaging
from google.cloud import firestore, storage
from flask import escape
from pdf_highlights.Statistic import Statistics
from pdf_highlights.TextStore import Token
from pdf_highlights.PDFpos import PDFpos
from pdf_highlights.MasterPDF import GenerateMaster


class PDFhighlights:
    
    # Initialise the firestore and storage instance
    def __init__(self):
        self.db = firestore.Client()
        self.stor = storage.Client()

   
    # Function to create new collection on firebase when new pdf is uploaded
    def new_pdf(self, wordlist, filename):
        # Initialises the nested collection and creates a counter to track the number of uploads
        stats_collection = self.db.collection(u'pdfs').document(filename).collection(u'words')
        stats_collection.document(u'total').set({
            u'total' : 1
        })

        # Iterates through the list generated after parsing the pdf
        for wordstore in wordlist:
            
            # Unique identifier within each document to identify each word
            name = str(wordstore.getPage()) + "_" + str((wordstore.getX1()+wordstore.getX2())/2) + "_" + str(wordstore.getY2())

            # Sets the information within the database
            current = stats_collection.document(name)
            x = wordstore.to_dict()
            current.set(x)       

    # Function to update highlights on cloud firebaes when existing pdf is uploaded
    def update_highlights(self, wordlist, filename):
        # Increments the firestore total upload count for that particular document
        stats_collection = self.db.collection(u'pdfs').document(filename).collection(u'words')
        stats_collection.document(u'total').update({u'total' : firestore.Increment(1)})

        # Iterates through the collection to upload the highlight count of each individual word on the firebase
        for wordstore in wordlist:
            name = str(wordstore.getPage()) + "_" + str((wordstore.getX1()+wordstore.getX2())/2) + "_" + str(wordstore.getY2())
            current = stats_collection.document(name)
            if current.get().exists:
                current.update({'count' : firestore.Increment(wordstore.getCount())})
            else:
                current.set(wordstore.to_dict())

        # Initialises the list before pulling the updated firebase collection. 
        text_list =  list()
        docs = stats_collection.stream()
        count = 1
        for doc in docs:
            current_doc = doc.to_dict()
            if len(current_doc) > 1:
                text_list.append(Token.from_dict(doc.to_dict()))
                text_list[-1].setCount(current_doc[u'count'])
            else:
                count = current_doc[u'total']
        return text_list, count

    def update_db(self, module, id, user, pdf_name):
        # First access the quiz ref
        quiz = self.db.collection('users').document(user).collection('Modules').document(module)
        quiz_col = quiz.get()
        quiz_dict = quiz_col.to_dict()
        quizzes = quiz_dict['quizzes']

        master = self.db.collection('MasterPDFMods').document(module).collection('PDFs').document(id)
        master_col = master.get()
        if master_col.exists:
            # change datetime
            master.update({'lastUpdated' : firestore.SERVER_TIMESTAMP})
        else:
            master.set({'lastUpdated' : firestore.SERVER_TIMESTAMP,
            'PDFName' : pdf_name})
        
        # add users
        users = master.collection('Users').document(user)
        users_col = users.get()
        if not users_col.exists:
            users.set({'subscribed' : True,
            'userFileName' : pdf_name})
        users.set({'quizzes' : quizzes})
        

    # Function to process the newly uploaded file from cloud storage
    def process(self, bucket_name, blob_name):
        # Initialises the bucket and the object path on cloud storage 
        bucket = self.stor.bucket(bucket_name)
        blob = bucket.blob(blob_name)
        
        # Obtains the current working directory in order to create a temporary folder within the container
        this = os.getcwd()
        if this[-1] != '/':
            this += '/'

        ## May have to move to tmp
        # Sets the download directory before downloading the file
        temp = '{}tmp/{}'.format(this, blob_name.split('/')[-1])
        check = '{}tmp'.format(this)
        if not os.path.isdir(check):
            logging.info('Directory %s is created.', check)
            os.mkdir(check)
        # logging.info('Download {}'.format(temp))
        blob.download_to_filename(temp)
        
        # Process the file and check if pdf exists
        current = Statistics()
        current_list = current.compute(temp, temp)

        # Obtain the unique hash for the file
        if len(current_list) > 0:
            filename = str(current_list[0].getHashed())
        else:
            return

        # Update the MasterPDFMods collection in firestore
        self.update_db(blob_name.split('/')[2], filename, blob_name.split('/')[1], str(current_list[0].getFilename()))
        doc_ref = self.db.collection(u'users').document(blob_name.split('/')[1])
        curr = doc_ref.get().to_dict()
        subscribtion_list = list()
        subscribtion_list.append(curr[u'token'])
        messaging.subscribe_to_topic(subscribtion_list, filename)

        # Check if the document exists
        doc_ref = self.db.collection('pdfs').document(filename).collection(u'words').document(u'total')
        doc = doc_ref.get()
        if doc.exists:
            # logging.info('filename: %s exists', filename)

            # Update the file on the cloud database before generating the master pdf
            text_list, maxcount = self.update_highlights(current_list, filename)
            master_pdf = GenerateMaster()
            master_pdf.main(temp, text_list, maxcount)
        else:   
            # logging.info('filename: %s does not exists, creating new entry', filename)
            # Initialise a new collection for the new pdf upload and generate the corresponding master pdf
            self.new_pdf(current_list, filename)
            master_pdf = GenerateMaster()
            master_pdf.main(temp, current_list, 1)
            
        # Set the new path to upload a text file containing the link to the master pdf
        file_len = len(blob_name.split('/')[-1])
        new_url = blob_name[:-file_len]
        new_url += 'link.txt'

        # Initialise the upload path for google cloud storage
        filename = filename + '.pdf'
        destination = 'master/{}'.format(filename)
        blob_up = bucket.blob(destination)
        blob_up.upload_from_filename(temp)  

        # Obtain and upload the link to the master pdf to the directory 
        master_url = blob_up.public_url    
        blob_link = bucket.blob(new_url)
        blob_link.upload_from_string(str(master_url))
        os.remove(temp) 
        return str(master_url) , filename



# test = PDFhighlights()
# test.process("hyper-beam.appspot.com/", "/pdf/tBqBjEWxZiRwGwMk2uzyEaYTNvl1/E2oIm06YtiiYQMbfsJMM/avatar.pdf")