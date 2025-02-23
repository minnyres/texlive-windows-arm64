#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include <string.h>
#include <malloc.h>
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

// #define SCRIPTLINK "../../texmf-dist/scripts/latexmk/latexmk.pl"
// #define INTERPRETER "perl.exe"

static int is_include_space(char* s)
{
	char* p;
	p = strchr(s, ' ');
	if (p) return 1;
	p = strchr(s, '\t');
	if (p) return 1;
	return 0;
}

int main(int argc, char* argv[])
{
	int i;
	char* p;

	fs::path wrapperPath = argv[0];
	fs::path scriptPath = wrapperPath.parent_path() / SCRIPTLINK;
	scriptPath.make_preferred();

	char** argvToPass = new char* [argc + 2];

	if (scriptPath.extension() == ".pl")
		argvToPass[0] = (char*)"perl.exe";
	else if (scriptPath.extension() == ".py")
		argvToPass[0] = (char*)"python.exe";
	else
#ifdef INTERPRETER
		argvToPass[0] = (char*)INTERPRETER;
#else
        return -1;
#endif

	std::string scriptPathStr = "\"" + scriptPath.string() + "\"";
	argvToPass[1] = (char*)scriptPathStr.c_str();

	for (i = 1; i < argc; i++) {
		if (is_include_space(argv[i])) {
			p = (char*)malloc(strlen(argv[i]) + 3);
			strcpy(p, "\"");
			strcat(p, argv[i]);
			strcat(p, "\"");
			free(argv[i]);
			argvToPass[i + 1] = p;
		}
		else
			argvToPass[i + 1] = argv[i];
	}
	argvToPass[argc + 1] = NULL;

	return _spawnvp(_P_WAIT, argvToPass[0], (const char* const*)argvToPass);
}