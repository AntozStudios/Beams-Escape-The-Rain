using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainBehaviour : MonoBehaviour
{
  
   
   [HideInInspector] public float ySpeed;
   public bool isRaining = true;
   public Material[] materials;



void Start(){
   
}

    // Update is called once per frame
    void Update()
    {
      

        if(GetComponent<Rigidbody>()!=null){
            if(isRaining){
                GetComponent<Rigidbody>().AddForce(new Vector3(0,-1,0)*ySpeed*Time.deltaTime,ForceMode.Acceleration);
            }

        }

        
    }

   

    public int getRandomMaterial(){
        return Random.Range(0,materials.Length);
    }

   
}
