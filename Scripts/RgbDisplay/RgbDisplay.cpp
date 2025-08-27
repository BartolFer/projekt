#include "./OpenGlDep/glad/include/glad/glad.h"
#include "./OpenGlDep/glfw-3.4.bin.WIN64/include/GLFW/glfw3.h"
#include <iostream>
#include <chrono>
#include <thread>

#include "../../Targets/Examples/Metadata.hpp"

// Vertex Shader Source
const char* vertexShaderSource = R"(
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;

out vec2 TexCoord;

void main() {
	gl_Position = vec4(aPos, 1.0);
	TexCoord = aTexCoord;
}
)";

// Fragment Shader Source
const char* fragmentShaderSource = R"(
#version 330 core
out vec4 FragColor;

in vec2 TexCoord;
uniform sampler2D ourTexture;

void main() {
	FragColor = texture(ourTexture, TexCoord);
}
)";

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
	glViewport(0, 0, width, height);
}

void checkCompileErrors(GLuint shader, std::string type) {
	GLint success;
	GLchar infoLog[1024];
	if (type != "PROGRAM") {
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (!success) {
			glGetShaderInfoLog(shader, 1024, NULL, infoLog);
			std::cerr << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n" << infoLog << "\n";
		}
	} else {
		glGetProgramiv(shader, GL_LINK_STATUS, &success);
		if (!success) {
			glGetProgramInfoLog(shader, 1024, NULL, infoLog);
			std::cerr << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n" << infoLog << "\n";
		}
	}
}

std :: ostream& operator<<(std :: ostream& stream, const MetaData& meta_data) {
	return stream << "Image(" << meta_data.width << " x " << meta_data.height << ")";
}

//	void resizeToAspectRatio(MetaData meta_data) {
//		glfwGetWindowFrameSize()
//		glfwSetWindowAspectRatio
//	}

int main(int const argc, char const* const argv[]) {
	std :: cout << "Starting" << std :: endl;
	if (argc < 2) {
		std :: cerr << "Required positional parameter: path/to/image.rgb" << std :: endl;
		return EXIT_FAILURE;
	}
	char const* const image_path = argv[1];
	FILE* image = fopen(image_path, "rb");
	if (image == nullptr) {
		std :: cerr << "Image <" << image_path << "> doesn't exist" << std :: endl;
		return EXIT_FAILURE;
	}
	MetaData meta_data{ 0, 0, 3, };
	if (fread(&meta_data, sizeof(meta_data), 1, image) != 1) {
		std :: cerr << "Input file doesn't have metadata" << std :: endl;
		return EXIT_FAILURE;
	}
	std :: cout << meta_data << std :: endl;
	size_t total_pixels = meta_data.width * meta_data.height * meta_data.n_channels;
	uint8_t* data = new uint8_t[total_pixels + 12];
	if (fread(data, sizeof(data[0]), total_pixels + 12, image) < total_pixels) {
		std :: cerr << "Input file doesn't have enogh bytes" << std :: endl;
		return EXIT_FAILURE;
	}
	fclose(image);
	// flip image horizontally
	for (int i = 0; i < meta_data.height / 2; ++i) {
		for (int j = 0; j < meta_data.width; ++j) {
			int i_flip = meta_data.height - i - 1;
			int index1 = (i      * meta_data.width + j) * meta_data.n_channels;
			int index2 = (i_flip * meta_data.width + j) * meta_data.n_channels;
			// printf("%d %d: #%02x%02x%02x <-> #%02x%02x%02x\n", i, i_flip, data[index1 + 0], data[index1 + 1], data[index1 + 2], data[index2 + 0], data[index2 + 1], data[index2 + 2]);
			for (int c = 0; c < meta_data.n_channels; ++c) {
				std :: swap(data[index1 + c], data[index2 + c]);
			}
		}
	}
	// for (int i = 0; i < meta_data.width * meta_data.height; ++i) {
	// 	printf("#%02x%02x%02x\n", data[3*i + 0], data[3*i + 1], data[3*i + 2]);
	// }

	std :: this_thread :: sleep_for(std :: chrono :: seconds(1));

	// Initialize GLFW
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// Create a GLFW window
	
	int w_width  = std :: max(meta_data.width , 100);
	int w_height = std :: max(meta_data.height, 100);
	GLFWwindow* window = glfwCreateWindow(w_width, w_height, "RGB Display", NULL, NULL);
	if (window == NULL) {
		std::cerr << "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;
	}
	glfwMakeContextCurrent(window);
	
	// Initialize GLAD
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
		std::cerr << "Failed to initialize GLAD" << std::endl;
		return -1;
	}
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetWindowAspectRatio(window, meta_data.width, meta_data.height);

	// Compile shaders
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
	glCompileShader(vertexShader);
	checkCompileErrors(vertexShader, "VERTEX");

	GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
	glCompileShader(fragmentShader);
	checkCompileErrors(fragmentShader, "FRAGMENT");

	GLuint shaderProgram = glCreateProgram();
	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);
	glLinkProgram(shaderProgram);
	checkCompileErrors(shaderProgram, "PROGRAM");

	glDeleteShader(vertexShader);
	glDeleteShader(fragmentShader);

	// Vertex data
	float vertices[] = {
		// positions		// texture coords
		1.0f,  1.0f, 0.0f,  1.0f, 1.0f,
		1.0f, -1.0f, 0.0f,  1.0f, 0.0f,
	   -1.0f, -1.0f, 0.0f,  0.0f, 0.0f,
	   -1.0f,  1.0f, 0.0f,  0.0f, 1.0f
	};
	unsigned int indices[] = {
		0, 1, 3,
		1, 2, 3
	};

	GLuint VAO, VBO, EBO;
	glGenVertexArrays(1, &VAO);
	glGenBuffers(1, &VBO);
	glGenBuffers(1, &EBO);

	glBindVertexArray(VAO);

	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
	glEnableVertexAttribArray(1);

	// Load texture
	GLuint texture;
	glGenTextures(1, &texture);
	glBindTexture(GL_TEXTURE_2D, texture);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	
	// stbi_set_flip_vertically_on_load(true);
	// unsigned char* data = stbi_load("path/to/your/image.jpg", &width, &height, &nrChannels, 0);
	if (data) {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, meta_data.width, meta_data.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
		glGenerateMipmap(GL_TEXTURE_2D);
	} else {
		std::cerr << "Failed to load texture" << std::endl;
	}
	// stbi_image_free(data);

	// Render loop
	while (!glfwWindowShouldClose(window)) {
		glClear(GL_COLOR_BUFFER_BIT);

		glUseProgram(shaderProgram);
		glBindTexture(GL_TEXTURE_2D, texture);
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

		glfwSwapBuffers(window);
		glfwPollEvents();
		std :: this_thread :: sleep_for(std :: chrono :: milliseconds(100));
	}

	// Cleanup
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);

	glfwTerminate();
	return 0;
}
