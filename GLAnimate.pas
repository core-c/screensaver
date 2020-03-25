unit GLAnimate;
interface
uses windows, OpenGL, graphics, classes;


type TCoreGL=Object
       StillBusy: boolean;
       ForceRect: TRect;
       procedure EnableOpenGL(handleWnd:HWND; var _handleDC:HDC; var _handleRC:HGLRC);
       procedure DisableOpenGL(handleWnd:HWND; _handleDC:HDC; _handleRC:HGLRC);
     private
     public
     end;



var CoreGL: TCoreGL;
    FormBackground: hwnd;  {Handle of OpenGL-context}
    handleDC: HDC;         {OpenGL HandleDeviceContext}
    handleRC: HGLRC;       {OpenGL HandleopenGLRenderContext}


  glCopyTexImage2D: procedure (target: GLenum; level, components: GLint; x,y,width,height: GLsizei; border: GLint); stdcall = nil;
  procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external 'opengl32.dll';
  procedure glDeleteTextures(n: GLsizei; textures: PGLuint); stdcall; external 'opengl32.dll';
  procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external 'opengl32.dll';

implementation







{Enable OpenGL}
procedure TCoreGL.EnableOpenGL(handleWnd:HWND; var _handleDC:HDC; var _handleRC:HGLRC);
var pfd: PIXELFORMATDESCRIPTOR;
    iFormat: integer;
begin
  {get the device context (DC)}
  _handleDC:=GetDC(handleWnd);
  {set the pixel format for the DC}
  ZeroMemory(@pfd, sizeof(pfd));
  pfd.nSize:=sizeof(pfd);
  pfd.nVersion:=1;
  pfd.dwFlags:=(PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER);
  pfd.iPixelType:=PFD_TYPE_RGBA;
  pfd.cColorBits:=24;
  pfd.cDepthBits:=24;
  pfd.iLayerType:=PFD_MAIN_PLANE;
  iFormat:=ChoosePixelFormat(_handleDC,@pfd);
  SetPixelFormat(_handleDC,iFormat,@pfd);
  {create and enable the render context (RC)}
  _handleRC:=wglCreateContext(_handleDC);
  wglMakeCurrent(_handleDC,_handleRC);

  glCopyTexImage2D := wglGetProcAddress('glCopyTexImage2D');

//  LoadHCPFile('roeland2.hcp');
  { set viewing projection }
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glFrustum(-0.77,0.77,   -0.77, 0.77,   0.85,2.85);
  glMatrixMode(GL_MODELVIEW);
  glTranslatef(0.0, -0.2, -1.0);
  {}
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_ALWAYS);
  glDepthRange(0.0, 1.0);
  {}
  glEnable(GL_CULL_FACE);
  glFrontFace(GL_CCW);
  {}
end;

{Disable OpenGL}
procedure TCoreGL.DisableOpenGL(handleWnd:HWND; _handleDC:HDC; _handleRC:HGLRC);
begin
  wglMakeCurrent(0,0);
  wglDeleteContext(_handleRC);
  ReleaseDC(handleWnd,_handleDC);
end;




end.
