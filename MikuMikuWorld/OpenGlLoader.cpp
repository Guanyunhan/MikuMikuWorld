#define STB_IMAGE_IMPLEMENTATION
#define STBI_WINDOWS_UTF8

#include "Application.h"
#include "ApplicationConfiguration.h"
#include "IO.h"
#include "UI.h"
#include "stb_image.h"

namespace MikuMikuWorld
{
	void frameBufferResizeCallback(GLFWwindow* window, int width, int height)
	{
		glViewport(0, 0, width, height);
	}

	void windowSizeCallback(GLFWwindow* window, int width, int height)
	{
		if (!Application::windowState.maximized)
		{
			Application::windowState.size.x = width;
			Application::windowState.size.y = height;
		}
	}

	void windowPositionCallback(GLFWwindow* window, int x, int y)
	{
		if (!Application::windowState.maximized)
		{
			Application::windowState.position.x = x;
			Application::windowState.position.y = y;
		}
	}

	void windowCloseCallback(GLFWwindow* window)
	{
		glfwSetWindowShouldClose(window, 0);
		Application::windowState.closing = true;
	}

	void windowMaximizeCallback(GLFWwindow* window, int _maximized)
	{
		Application::windowState.maximized = _maximized;
	}

	Result Application::initOpenGL()
	{
		// GLFW initializion
		const char* glfwErrorDescription = NULL;
		int possibleError = GLFW_NO_ERROR;

#if defined(__APPLE__)
		glfwInitHint(GLFW_ANGLE_PLATFORM_TYPE, GLFW_ANGLE_PLATFORM_TYPE_METAL);
#endif
		glfwInit();
		possibleError = glfwGetError(&glfwErrorDescription);
		if (possibleError != GLFW_NO_ERROR)
		{
			glfwTerminate();
			return Result(ResultStatus::Error, "Failed to initialize GLFW.\n" + std::string(glfwErrorDescription));
		}

		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
		glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
		glfwWindowHint(GLFW_CONTEXT_CREATION_API, GLFW_EGL_CONTEXT_API);

		window = glfwCreateWindow(config.windowSize.x, config.windowSize.y, APP_NAME, NULL, NULL);
		possibleError = glfwGetError(&glfwErrorDescription);
		if (possibleError != GLFW_NO_ERROR)
		{
			glfwTerminate();
			return Result(ResultStatus::Error, "Failed to create GLFW Window.\n" + std::string(glfwErrorDescription));
		}

		glfwSetWindowPos(window, config.windowPos.x, config.windowPos.y);
		glfwMakeContextCurrent(window);
		glfwSetWindowTitle(window, APP_NAME " - Untitled");
		glfwSetWindowPosCallback(window, windowPositionCallback);
		glfwSetWindowSizeCallback(window, windowSizeCallback);
		glfwSetFramebufferSizeCallback(window, frameBufferResizeCallback);
		glfwSetWindowCloseCallback(window, windowCloseCallback);
		glfwSetWindowMaximizeCallback(window, windowMaximizeCallback);

		std::string iconFilename = resDir.string() + "mmw_icon.png";
		if (IO::File::exists(iconFilename))
		{
			GLFWimage images[1]{};
			images[0].pixels = stbi_load(iconFilename.c_str(), &images[0].width, &images[0].height, 0, 4); //rgba channels 
			glfwSetWindowIcon(window, 1, images);
			stbi_image_free(images[0].pixels);
		}

		glfwSwapInterval(config.vsync);
		if (config.maximized)
			glfwMaximizeWindow(window);

		glLineWidth(1.0f);
		glEnable(GL_BLEND);
		glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
		glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
		glViewport(0, 0, config.windowSize.x, config.windowSize.y);

		return Result::Ok();
	}
}
