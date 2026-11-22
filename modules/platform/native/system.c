#include "platform_internal.h"

#if defined(SDL_PLATFORM_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <sys/sysctl.h>
#elif defined(SDL_PLATFORM_ANDROID)
#include <sys/system_properties.h>
#elif defined(__unix__)
#include <stdio.h>
#include <sys/utsname.h>
#endif

#if defined(SDL_PLATFORM_WIN32)
static const wchar_t windows_version_key[] = L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";

static void read_windows_version_string(const wchar_t* value, char* output, int capacity) {
	wchar_t buffer[256];
	DWORD size = sizeof(buffer);
	if (RegGetValueW(HKEY_LOCAL_MACHINE, windows_version_key, value, RRF_RT_REG_SZ | RRF_SUBKEY_WOW6464KEY,
		nullptr, buffer, &size) == ERROR_SUCCESS)
		WideCharToMultiByte(CP_UTF8, 0, buffer, -1, output, capacity, nullptr, nullptr);
}
#elif defined(SDL_PLATFORM_LINUX)
static void read_linux_distribution(char* name, size_t capacity) {
	FILE* file = fopen("/etc/os-release", "r");
	if (file == nullptr)
		file = fopen("/usr/lib/os-release", "r");
	if (file == nullptr)
		return;

	char line[512];
	while (fgets(line, sizeof(line), file) != nullptr) {
		if (SDL_strncmp(line, "PRETTY_NAME=", 12) != 0)
			continue;

		const char* value = line + 12;
		const char quote = (*value == '"' || *value == '\'') ? *value++ : '\0';
		size_t index = 0;
		while (*value && *value != quote && *value != '\r' && *value != '\n' && index + 1 < capacity) {
			if (*value == '\\' && quote != '\'' && value[1] && SDL_strchr("\\\"$`", value[1]))
				value++;
			name[index++] = *value++;
		}
		name[index] = '\0';
		break;
	}
	fclose(file);
}
#endif

static const char* process_architecture(void) {
#if defined(_M_ARM64EC) || defined(_M_ARM64) || defined(__aarch64__)
	return "arm64";
#elif defined(_M_X64) || defined(__x86_64__)
	return "x86-64";
#elif defined(_M_IX86) || defined(__i386__)
	return "x86";
#elif defined(_M_ARM) || defined(__arm__)
	return "arm";
#elif defined(__riscv) && __riscv_xlen == 64
	return "riscv64";
#elif defined(__powerpc64__)
	return "ppc64";
#else
	return "unknown architecture";
#endif
}

HL_PRIM vbyte* HL_NAME(get_system_info)(void) {
	char name[256] = {0};
	char version[128] = {0};
	char build[256] = {0};
	const char* build_label = "build";

#if defined(SDL_PLATFORM_WIN32)
	char installation[32] = {0};
	char build_number[32] = {0};
	read_windows_version_string(L"ProductName", name, sizeof(name));
	read_windows_version_string(L"DisplayVersion", version, sizeof(version));
	if (version[0] == '\0')
		read_windows_version_string(L"ReleaseId", version, sizeof(version));
	read_windows_version_string(L"CurrentBuildNumber", build_number, sizeof(build_number));
	read_windows_version_string(L"InstallationType", installation, sizeof(installation));
	if (SDL_strcmp(installation, "Client") == 0 && SDL_atoi(build_number) >= 22000 && SDL_strncmp(name, "Windows 10", 10) == 0)
		name[9] = '1';

	if (build_number[0] != '\0') {
		DWORD revision;
		DWORD size = sizeof(revision);
		if (RegGetValueW(HKEY_LOCAL_MACHINE, windows_version_key, L"UBR", RRF_RT_REG_DWORD | RRF_SUBKEY_WOW6464KEY,
			nullptr, &revision, &size) == ERROR_SUCCESS)
			SDL_snprintf(build, sizeof(build), "%s.%lu", build_number, (unsigned long)revision);
		else
			SDL_strlcpy(build, build_number, sizeof(build));
	}
#elif defined(__APPLE__)
	size_t version_size = sizeof(version);
	if (sysctlbyname("kern.osproductversion", version, &version_size, nullptr, 0) != 0)
		version[0] = '\0';
	size_t build_size = sizeof(build);
	if (sysctlbyname("kern.osversion", build, &build_size, nullptr, 0) != 0)
		build[0] = '\0';
#elif defined(SDL_PLATFORM_ANDROID)
	char property[PROP_VALUE_MAX];
	if (__system_property_get("ro.build.version.release", property) > 0)
		SDL_strlcpy(version, property, sizeof(version));
	if (__system_property_get("ro.build.id", property) > 0)
		SDL_strlcpy(build, property, sizeof(build));
#elif defined(__unix__)
#if defined(SDL_PLATFORM_LINUX)
	read_linux_distribution(name, sizeof(name));
#endif
	struct utsname os;
	if (uname(&os) == 0)
		SDL_strlcpy(build, os.release, sizeof(build));
	build_label = "kernel";
#endif

	char build_suffix[280] = {0};
	if (build[0] != '\0')
		SDL_snprintf(build_suffix, sizeof(build_suffix), " (%s %s)", build_label, build);

	char info[768];
	SDL_snprintf(info, sizeof(info), "%s%s%s%s | %s | %d logical cores | %d MiB RAM",
		name[0] == '\0' ? SDL_GetPlatform() : name,
		version[0] == '\0' ? "" : " ", version, build_suffix, process_architecture(),
		SDL_GetNumLogicalCPUCores(), SDL_GetSystemRAM());
	return hl_copy_bytes(info, (int)strlen(info) + 1);
}
DEFINE_PRIM(_BYTES, get_system_info, _NO_ARG);

HL_PRIM int HL_NAME(get_power_state)() {
	return SDL_GetPowerInfo(nullptr, nullptr);
}
DEFINE_PRIM(_I32, get_power_state, _NO_ARG);

HL_PRIM int HL_NAME(get_battery_percent)() {
	int percent = -1;

	if (SDL_GetPowerInfo(nullptr, &percent) == SDL_POWERSTATE_ERROR)
		return -1;

	return percent;
}
DEFINE_PRIM(_I32, get_battery_percent, _NO_ARG);

HL_PRIM int HL_NAME(get_system_theme)() {
	return SDL_GetSystemTheme();
}
DEFINE_PRIM(_I32, get_system_theme, _NO_ARG);

HL_PRIM const char* HL_NAME(get_platform)() {
	return SDL_GetPlatform();
}
DEFINE_PRIM(_BYTES, get_platform, _NO_ARG);

HL_PRIM vbyte* HL_NAME(get_base_path)() {
	const char* path = SDL_GetBasePath();

	return path == nullptr ? nullptr : hl_copy_bytes(path, (int)strlen(path) + 1);
}
DEFINE_PRIM(_BYTES, get_base_path, _NO_ARG);

HL_PRIM vbyte* HL_NAME(get_current_directory)() {
	char* path = SDL_GetCurrentDirectory();

	if (path == nullptr)
		return nullptr;

	vbyte* result = hl_copy_bytes(path, (int)strlen(path) + 1);
	SDL_free(path);

	return result;
}
DEFINE_PRIM(_BYTES, get_current_directory, _NO_ARG);
