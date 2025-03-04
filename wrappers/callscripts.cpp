#include <process.h>
#include <string>
#include <malloc.h>
#include <iostream>
#include <filesystem>
#include <cstdlib>
#include <kpathsea/kpathsea.h>

namespace fs = std::filesystem;

//#define SCRIPTLINK "scripts/latexmk/latexmk.pl"
//#define INTERPRETER "perl.exe"

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
	// get texmf-dist path
	fs::path process_path = argv[0];
	fs::path texmf_dist_path = process_path.parent_path() / "../../texmf-dist";

	if (!fs::exists(texmf_dist_path)) // use kpathsea if the path does not exist
	{
		kpathsea kpse = kpathsea_new();
		kpathsea_set_program_name(kpse, argv[0], NULL);
		texmf_dist_path = kpathsea_var_value(kpse, "TEXMFDIST");
	}
	// get script path
	fs::path script_path = texmf_dist_path / SCRIPTLINK;
	script_path.make_preferred();
	std::string script_path_string = "\"" + script_path.string() + "\"";

	if (!fs::exists(script_path))
	{
		std::cerr << "I cannot find the script file " << script_path_string << "...\n";
		return 1;
	}

	char** argv_to_pass = new char* [argc + 2];

	if (script_path.extension() == ".pl")
		argv_to_pass[0] = (char*)"perl.exe";
	else if (script_path.extension() == ".py")
		argv_to_pass[0] = (char*)"python.exe";
	else if (script_path.extension() == ".tlu" || script_path.extension() == ".lua" || script_path.extension() == ".texlua")
		argv_to_pass[0] = (char*)"texlua.exe";
	else if (script_path.extension() == ".sh")
		argv_to_pass[0] = (char*)"bash.exe";
	else if (script_path.extension() == ".tcl")
		argv_to_pass[0] = (char*)"tclsh.exe";
	else if (script_path.extension() == ".rb")
		argv_to_pass[0] = (char*)"ruby.exe";
	else
#ifdef INTERPRETER
		argv_to_pass[0] = (char*)INTERPRETER;
#else
		return 2;
#endif

	argv_to_pass[1] = (char*)script_path_string.c_str();
	char* p;

	for (int i = 1; i < argc; i++) {
		if (is_include_space(argv[i])) {
			p = (char*)malloc(strlen(argv[i]) + 3);
			strcpy(p, "\"");
			strcat(p, argv[i]);
			strcat(p, "\"");
			free(argv[i]);
			argv_to_pass[i + 1] = p;
		}
		else
			argv_to_pass[i + 1] = argv[i];
	}
	argv_to_pass[argc + 1] = NULL;

	// append the environment PATH
	char* env_path = std::getenv("PATH");
	char* env_msys2 = std::getenv("MSYS2_PATH_FOR_TEXLIVE");
	std::string env_path_string = "PATH=" + std::string(env_path);

	if (env_msys2)
		env_path_string = env_path_string + ";" + std::string(env_msys2) + "/clangarm64/bin;" + std::string(env_msys2) + "/usr/bin";

	env_path_string = env_path_string + ";" + texmf_dist_path.string() + "/../tlpkg/tlperl/bin;"
		+ texmf_dist_path.string() + "/../tlpkg/tltcl/bin;"
		+ texmf_dist_path.string() + "/../tlpkg/tlgs/bin";

	putenv(env_path_string.c_str());

	return _spawnvp(_P_WAIT, argv_to_pass[0], (const char* const*)argv_to_pass);
}