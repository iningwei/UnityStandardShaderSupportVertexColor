Shader "My/VertColor/Legacy Shaders/VertexLitVertColor" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Spec Color", Color) = (1,1,1,1)
	_Emission ("Emissive Color", Color) = (0,0,0,0)
	_Shininess ("Shininess", Range (0.01, 1)) = 0.7
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

SubShader {
	Tags { "RenderType"="Opaque" }
	LOD 100
	
	// Non-lightmapped
	Pass {
		Tags { "LightMode" = "Vertex" }
		
		Material {
			Diffuse [_Color]
			Ambient [_Color]
			Shininess [_Shininess]
			Specular [_SpecColor]
			Emission [_Emission]
		} 
		Lighting On
		SeparateSpecular On
		ColorMaterial AmbientAndDiffuse
		SetTexture [_MainTex] {
			constantColor (1,1,1,1)
			Combine texture * primary DOUBLE, constant // UNITY_OPAQUE_ALPHA_FFP
		} 
	}
	
	// Lightmapped, encoded as dLDR
	Pass {
		Tags { "LightMode" = "VertexLM" }
		
		BindChannels {
			Bind "Vertex", vertex
			Bind "normal", normal
			Bind "Color", color
			Bind "texcoord1", texcoord0 // lightmap uses 2nd uv
			Bind "texcoord", texcoord1 // main uses 1st uv
		}

		ColorMaterial AmbientAndDiffuse
		
		SetTexture [unity_Lightmap] {
			matrix [unity_LightmapMatrix]
			constantColor [_Color]
			combine texture * constant
		}
		SetTexture [_MainTex] {
			constantColor (1,1,1,1)
			combine texture * previous DOUBLE, constant // UNITY_OPAQUE_ALPHA_FFP
		}
	}
	
	// Lightmapped, encoded as RGBM
	Pass {
		Tags { "LightMode" = "VertexLMRGBM" }
		
		BindChannels {
			Bind "Vertex", vertex
			Bind "normal", normal
			Bind "Color", color
			Bind "texcoord1", texcoord0 // lightmap uses 2nd uv
			Bind "texcoord1", texcoord1 // unused
			Bind "texcoord", texcoord2 // main uses 1st uv
		}
		
		ColorMaterial AmbientAndDiffuse
		
		SetTexture [unity_Lightmap] {
			matrix [unity_LightmapMatrix]
			combine texture * texture alpha DOUBLE
		}
		SetTexture [unity_Lightmap] {
			constantColor [_Color]
			combine previous * constant
		}
		SetTexture [_MainTex] {
			constantColor (1,1,1,1)
			combine texture * previous QUAD, constant // UNITY_OPAQUE_ALPHA_FFP
		}
	}
	
	// Pass to render object as a shadow caster
	Pass {
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }
		
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma multi_compile_shadowcaster
#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
#include "UnityCG.cginc"

struct v2f { 
	V2F_SHADOW_CASTER;
	UNITY_VERTEX_OUTPUT_STEREO
};

v2f vert( appdata_base v )
{
	v2f o;
	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
	return o;
}

float4 frag( v2f i ) : SV_Target
{
	SHADOW_CASTER_FRAGMENT(i)
}
ENDCG

	}
	
}

}
