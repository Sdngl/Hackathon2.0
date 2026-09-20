from io import BytesIO
from PIL import Image
from django.core.files.uploadedfile import SimpleUploadedFile
def image_file(fmt='JPEG',name=None):
    b=BytesIO(); Image.new('RGB',(10,10),'white').save(b,format=fmt); ext={'JPEG':'jpg','PNG':'png','WEBP':'webp'}[fmt]
    mime={'JPEG':'image/jpeg','PNG':'image/png','WEBP':'image/webp'}[fmt]
    return SimpleUploadedFile(name or f'x.{ext}',b.getvalue(),content_type=mime)
