#define HL_NAME(n) limen_d3d12_##n
#include <hl.h>
#undef _GUID

#ifdef HL_WIN_DESKTOP
#include <d3d12.h>
#include <cwchar>
#endif

#define _RES _ABSTRACT(dx_resource)

HL_PRIM void HL_NAME(command_list_pix_begin_event)(ID3D12GraphicsCommandList* l, UINT64 color, wchar_t const* formatString) {
	(void)color;
	l->BeginEvent(0, formatString, (UINT)((wcslen(formatString) + 1) * sizeof(wchar_t)));
}

HL_PRIM void HL_NAME(command_list_pix_end_event)(ID3D12GraphicsCommandList* l) {
	l->EndEvent();
}

DEFINE_PRIM(_VOID, command_list_pix_begin_event, _RES _I64 _BYTES);
DEFINE_PRIM(_VOID, command_list_pix_end_event, _RES);
