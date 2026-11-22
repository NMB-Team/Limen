#pragma once
#ifndef DIRECTX_H
#define DIRECTX_H

struct IDXGIAdapter3;

typedef struct dx_driver_ {
	IDXGIAdapter3* memory_adapter;
	ID3D11Device* device;
	ID3D11DeviceContext* context;
	IDXGISwapChain* swapchain;
	ID3D11RenderTargetView* renderTarget;
	D3D_FEATURE_LEVEL feature;
	int init_flags;
	int back_buffer_count;
	bool allow_tearing;
} dx_driver;

HL_PRIM dx_driver* limen_d3d11_get_driver();

#endif
