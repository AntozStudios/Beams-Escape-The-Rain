using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;

public class PlayerChildren : MonoBehaviour
{
    public Light playerLight;
    public ParticleSystem playerHit_ParticleSystem;
    public ParticleSystem rainHit_ParticleSystem;
    public ParticleSystem stars_ParticleSystem;
    public Camera playerCamera;
    
    private Renderer playerRenderer;

    void Awake()
    {
        playerRenderer = GetComponent<Renderer>();

        playerLight.color = playerRenderer.material.color;

        var main = playerHit_ParticleSystem.GetComponent<Renderer>();
        main.material = playerRenderer.material;
    }

    void Update()
    {
        playerLight.color = playerRenderer.material.color;

          var main = playerHit_ParticleSystem.GetComponent<Renderer>();
        main.material = playerRenderer.material;
    }
}
