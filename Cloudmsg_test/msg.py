from __future__ import print_function
import firebase_admin
import os
import logging
from firebase_admin import credentials, messaging
from google.cloud import firestore, storage
import google.cloud.logging
import datetime

token_dict = dict()


class PDFhighlights:
    
    # Initialise the firestore and storage instance
    def __init__(self):
        cred = credentials.Certificate("hyper-beam-firebase-adminsdk-3t5wg-60d7f00668.json")
        firebase_admin.initialize_app(cred)
        self.db = firestore.Client()
        log_client = google.cloud.logging.Client()
        log_client.get_default_handler()
        log_client.setup_logging()

    def send_to_user(self, uid, pdf_hash, pdf_name, pdf_link = ''):
        curr = token_dict.get(uid)
        if curr is None:
            doc_ref = self.db.collection(u'users').document(uid)
            curr = doc_ref.to_dict()[u'token']
            token_dict[uid] = curr
            message = messaging.Message(
                data={
                    'title': 'MasterPDF updated',
                    'message': 'The PDF : {} you uploaded has been processed.'.pdf_name,
                    'link' : pdf_link,
                },
                token=curr,
            )

        # Send a message to the device corresponding to the provided
        # registration token.
        response = messaging.send(message)
        # Response is a message ID string.
        logging.info("Message is sent to {} with a message id of {}".format(uid, response))
       

        # Create a button to suscribe users to a topic so that they can receive the latest updates from the master pdf whenever
        # there is a newer version of the master pdf
        # Topic can be suscribe to by both sides: idea 1 - when a user suscribes to a topic, the firebase is updated and I will use
        # messaging.subscribe_to_topic(tokens), where tokens is a non-empty list of tokens that wish to suscribe to a certain topic
        # benefit is that it allows me to check if a topic has any suscriptions before attempting to send the topic
        # Send to topic allows users to receive updates regarding a certain topic when a newer iteration is uploaded.
        def send_to_topic(self, topic, pdf_hash, pdf_name, pdf_link):
            # See documentation on defining a message payload.
            message = messaging.Message(
                data={
                    'title': 'MasterPDF updated',
                    'body   ': 'The PDF : {} you have subscribed to has a newer version. Click to view.',
                    'link' : pdf_link,
                },
                topic=topic,
            )

            # Send a message to the devices subscribed to the provided topic.
            response = messaging.send(message)
            logging.info("Message is sent to all users suscribe to topic {}".format(topic))

user1 = 'cU5BzH47Vn0:APA91bGL2XQpNVeH51FMgYQLsfC1mfOwa0d0Y0fqTo9_Nx8dXQ8fnJ_EwUHzaGKAg_tqBJtyBf3lsEngjwsEDGFBzrhXYTTMwyDf97SNQt2PzSpkVTwrmK1_jmmjOgmrhK2QZbKfUbpK'
link1 = 'https://storage.googleapis.com/hyper-beam.appspot.com/master/e443ce30f16dc6bddaa6c839f8fcfc81.pdf'
tester = PDFhighlights()
tester.send_to_user(user1,'e443ce30f16dc6bddaa6c839f8fcfc81', 'FinancialAccounting1.pdf', link1)