from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
class AuthTests(TestCase):
 def setUp(self): self.c=APIClient()
 def test_missing(self): self.assertEqual(self.c.post('/api/v1/chat/',{'message':'hi'},format='json').status_code,401)
 def test_malformed(self): self.c.credentials(HTTP_AUTHORIZATION='Bad token extra'); self.assertEqual(self.c.post('/api/v1/chat/',{'message':'hi'},format='json').status_code,401)
 @patch('authentication.firebase_auth._ensure_app')
 @patch('authentication.firebase_auth.auth.verify_id_token',side_effect=ValueError('bad'))
 def test_invalid(self,v,a): self.c.credentials(HTTP_AUTHORIZATION='Bearer bad'); self.assertEqual(self.c.post('/api/v1/chat/',{'message':'hi'},format='json').status_code,401)
 @patch('authentication.firebase_auth._ensure_app')
 @patch('authentication.firebase_auth.auth.verify_id_token',return_value={'uid':'u1'})
 @patch('chatbot.views.chat',return_value={'message':'ok'})
 def test_valid(self,ch,v,a): self.c.credentials(HTTP_AUTHORIZATION='Bearer good'); self.assertEqual(self.c.post('/api/v1/chat/',{'message':'hi'},format='json').status_code,200)
