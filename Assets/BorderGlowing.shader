Shader "Custom/EmissionEdges"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _EmissionTex ("Emission Map", 2D) = "white" {}
        _EmissionColor ("Emission Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 300

        Blend SrcAlpha OneMinusSrcAlpha
        AlphaTest Greater 0.1

        CGPROGRAM
        #pragma surface surf Lambert alpha:blend

        sampler2D _MainTex;
        sampler2D _EmissionTex;
        float4 _EmissionColor;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            float4 texColor = tex2D(_MainTex, IN.uv_MainTex);
            float4 emissionTex = tex2D(_EmissionTex, IN.uv_MainTex);

            // Nur die Emissions-Kanten verstärken
            float glow = max(emissionTex.r, emissionTex.g);
            o.Albedo = texColor.rgb;
            o.Alpha = texColor.a;
            o.Emission = _EmissionColor.rgb * glow;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
