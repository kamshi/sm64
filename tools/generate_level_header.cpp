#include <iostream>
#include <fstream>
#include <regex>
#include <string>

void generate_level_header(const std::string& input_file, const std::string& output_file) {
    std::ifstream input(input_file);
    if (!input) {
        std::cerr << "Failed to open input file: " << input_file << std::endl;
        exit(EXIT_FAILURE);
    }

    std::ofstream output(output_file);
    if (!output) {
        std::cerr << "Failed to open output file: " << output_file << std::endl;
        exit(EXIT_FAILURE);
    }

    std::string line;
    std::regex pattern(R"((.+))"); // Regex pattern to match any line

    while (std::getline(input, line)) {
        std::smatch match;
        if (std::regex_match(line, match, pattern)) {
            // Write the modified line to the output file
            output << "#include \"" << match[1] << "\"" << std::endl;
        }
    }

    input.close();
    output.close();
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input_file> <output_file>" << std::endl;
        return EXIT_FAILURE;
    }

    generate_level_header(argv[1], argv[2]);
    return EXIT_SUCCESS;
}
