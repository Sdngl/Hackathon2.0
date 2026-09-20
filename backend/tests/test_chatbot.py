from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
class ChatTests(TestCase):
 def setUp(self): self.c=APIClient(); self.c.force_authenticate(user=type('U',(),{'is_authenticated':True,'uid':'u'})())
 @patch('chatbot.views.chat',return_value={'message':'info','doctor_recommendation':{'needed':True,'speciality':'cardiology','reason':'symptoms'}})
 def test_valid_context_history_specialty(self,m):
  r=self.c.post('/api/v1/chat/',{'message':'explain','history':[{'role':'user','content':'x'}],'context':{'report':{'x':1}}},format='json'); self.assertEqual(r.status_code,200); self.assertEqual(r.data['data']['doctor_recommendation']['speciality'],'cardiology')
 def test_oversized_context(self): self.assertEqual(self.c.post('/api/v1/chat/',{'message':'x','context':{'x':'a'*21000}},format='json').status_code,400)
