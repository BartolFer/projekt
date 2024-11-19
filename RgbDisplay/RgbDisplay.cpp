#include "./OpenGlDep/glad/include/glad/glad.h"
#include "./OpenGlDep/glfw-3.4.bin.WIN64/include/GLFW/glfw3.h"
#include <iostream>

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

int main(int const argc, char const* const argv[]) {
	std :: cout << "Starting" << std :: endl;
	if (argc < 2) {
		std :: cerr << "Required positional parameter: path/to/image.rgb" << std :: endl;
		return EXIT_FAILURE;
	}
	char const* const image_path = argv[1];
	// Initialize GLFW
	std :: cout << "Here 0" << std :: endl;
	glfwInit();
	std :: cout << "Here 1" << std :: endl;
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	std :: cout << "Here 2" << std :: endl;
	// Create a GLFW window
	GLFWwindow* window = glfwCreateWindow(800, 600, "Texture Example", NULL, NULL);
	std :: cout << "Here 3" << std :: endl;
	if (window == NULL) {
		std::cerr << "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;
	}
	std :: cout << "Here 4" << std :: endl;
	glfwMakeContextCurrent(window);
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

	// Initialize GLAD
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
		std::cerr << "Failed to initialize GLAD" << std::endl;
		return -1;
	}

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
		0.5f,  0.5f, 0.0f,  1.0f, 1.0f,
		0.5f, -0.5f, 0.0f,  1.0f, 0.0f,
	   -0.5f, -0.5f, 0.0f,  0.0f, 0.0f,
	   -0.5f,  0.5f, 0.0f,  0.0f, 1.0f
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

	FILE* image = fopen(image_path, "rb");
	if (image == nullptr) {
		std :: cerr << "Image <" << image_path << "> doesn't exist" << std :: endl;
		return EXIT_FAILURE;
	}
	struct { int width=0, height=0, nrChannels=3; } meta_data;
	fread(&meta_data, sizeof(meta_data), 1, image);
	std :: cout << meta_data.width << " x " << meta_data.height << std :: endl;
	if (meta_data.width != 2 || meta_data.height != 2) {
		return 17;
	}
	uint8_t* data = new uint8_t[meta_data.width * meta_data.height * 3 + 12];
	fread(data, sizeof(data[0]), meta_data.width * meta_data.height * 3 + 12, image);
	// flip image horizontally
	for (int i = 0; i < meta_data.height / 2; ++i) {
		for (int j = 0; j < meta_data.width; ++j) {
			int i_flip = meta_data.height - i - 1;
			int index1 = (i      * meta_data.width + j) * 3;
			int index2 = (i_flip * meta_data.width + j) * 3;
			// printf("%d %d: #%02x%02x%02x <-> #%02x%02x%02x\n", i, i_flip, data[index1 + 0], data[index1 + 1], data[index1 + 2], data[index2 + 0], data[index2 + 1], data[index2 + 2]);
			std :: swap(data[index1 + 0], data[index2 + 0]);
			std :: swap(data[index1 + 1], data[index2 + 1]);
			std :: swap(data[index1 + 2], data[index2 + 2]);
		}
	}
	// for (int i = 0; i < meta_data.width * meta_data.height; ++i) {
	// 	printf("#%02x%02x%02x\n", data[3*i + 0], data[3*i + 1], data[3*i + 2]);
	// }
	
	// stbi_set_flip_vertically_on_load(true);
	// unsigned char* data = stbi_load("path/to/your/image.jpg", &width, &height, &nrChannels, 0);
	if (data) {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, meta_data.width, meta_data.height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
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
	}

	// Cleanup
	glDeleteVertexArrays(1, &VAO);
	glDeleteBuffers(1, &VBO);
	glDeleteBuffers(1, &EBO);

	glfwTerminate();
	return 0;
}
