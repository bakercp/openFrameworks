#include "ofAppRunner.h"
#include "ofApp.h"

int main(){
	// ofSetupOpenGL sets up a default OpenGL window for ofApp. The initial
	// window width, height and fullscreen status (OF_WINDOW or OF_FULLSCREEN)
	// can be set here. Window shape and fullscreen status can changed elsewhere
	// with ofSetWindowShape(x, y) and ofSetFullscreen(fullscreen) respectively.
	ofSetupOpenGL(1024, 768, OF_WINDOW);
	return ofRunApp(std::make_shared<ofApp>());
}


#ifdef TARGET_ANDROID
#include <jni.h>

extern "C"{
	void Java_cc_openframeworks_OFAndroid_init( JNIEnv*  env, jobject  thiz ){
		main();
	}
}
#endif
