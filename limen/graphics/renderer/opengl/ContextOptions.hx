package limen.graphics.renderer.opengl;

import limen.graphics.PresentMode;

typedef ContextOptions = {
	?minimumMajor:Int,
	?minimumMinor:Int,
	?maximumMajor:Int,
	?maximumMinor:Int,
	?depthBits:Int,
	?stencilBits:Int,
	?samples:Int,
	?flags:Int,
	?presentMode:PresentMode
}
