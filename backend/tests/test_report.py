from unittest.mock import patch
from django.test import TestCase
from rest_framework.test import APIClient
from django.core.files.uploadedfile import SimpleUploadedFile
from ai.client import AIInvalidResponse
from .helpers import image_file
class ReportTests(TestCase):
 def setUp(self): self.c=APIClient(); self.c.force_authenticate(user=type('U',(),{'is_authenticated':True,'uid':'u'})())
 @patch('analyzer.views.analyze_report',return_value={'type':'report','report':{'results':[],'summary':'x','uncertain_fields':[]}})
 def test_image(self,m): self.assertEqual(self.c.post('/api/v1/analyze/report/',{'image':image_file()},format='multipart').status_code,200)
 def test_invalid(self): self.assertEqual(self.c.post('/api/v1/analyze/report/',{'file':SimpleUploadedFile('x.pdf',b'no',content_type='application/pdf')},format='multipart').status_code,400)
 @patch('analyzer.views.analyze_report',return_value={'type':'report','report':{'results':[{'test_name':'Hb'}],'summary':'x','uncertain_fields':[]}})
 def test_structured(self,m): self.assertEqual(self.c.post('/api/v1/analyze/report/',{'file':SimpleUploadedFile('x.pdf',b'%PDF-1.4\n',content_type='application/pdf')},format='multipart').status_code,200)
 @patch('analyzer.views.analyze_report',side_effect=AIInvalidResponse('bad'))
 def test_malformed(self,m): self.assertEqual(self.c.post('/api/v1/analyze/report/',{'image':image_file()},format='multipart').status_code,502)
