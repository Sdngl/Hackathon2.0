from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from ai.client import AIInvalidResponse,AIServiceError
from .helpers import image_file
class MealTests(TestCase):
 def setUp(self):
  self.c=APIClient(); self.c.force_authenticate(user=type('U',(),{'is_authenticated':True,'uid':'u'})())
 @patch('analyzer.views.analyze_meal',return_value={'type':'meal','foods':[],'nutrition':{},'is_estimate':True,'notes':[]})
 def test_jpeg(self,m): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':image_file()},format='multipart').status_code,200)
 @patch('analyzer.views.analyze_meal',return_value={'type':'meal'})
 def test_png(self,m): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':image_file('PNG')},format='multipart').status_code,200)
 def test_unsupported(self): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':__import__('django').core.files.uploadedfile.SimpleUploadedFile('x.txt',b'abc',content_type='text/plain')},format='multipart').status_code,400)
 def test_empty(self): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':__import__('django').core.files.uploadedfile.SimpleUploadedFile('x.jpg',b'',content_type='image/jpeg')},format='multipart').status_code,400)
 @patch('analyzer.views.analyze_meal',side_effect=AIInvalidResponse('bad'))
 def test_malformed_ai(self,m): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':image_file()},format='multipart').status_code,502)
 @patch('analyzer.views.analyze_meal',side_effect=AIServiceError('down'))
 def test_ai_failure(self,m): self.assertEqual(self.c.post('/api/v1/analyze/meal/',{'image':image_file()},format='multipart').status_code,503)
