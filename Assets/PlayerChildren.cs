using UnityEngine;

public class PlayerChildren : MonoBehaviour
{
    public Light playerLight;
    public ParticleSystem playerHit_ParticleSystem;
   public ParticleSystem rainHit_ParticleSystem;
 public ParticleSystem stars_ParticleSystem;
public Camera playerCamera;

void Awake(){
    playerLight.color = GetComponent<Renderer>().material.color;
}
  void Update()
    {
            playerLight.color = GetComponent<Renderer>().material.color;
        
    }
}
