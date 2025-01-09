using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;

public class RainCollision : MonoBehaviour
{
    
    public Vector3 initPos;
    [SerializeField] GameObject rainFallOutPrefab;
    
    public bool isGrounding;
    

void Awake(){
  GetComponent<Rigidbody>().collisionDetectionMode = CollisionDetectionMode.Continuous;

}
   
void Start(){

    initPos = GetComponent<Rigidbody>().transform.position;
   
    
    
       
}
 

    [System.Obsolete]
    void OnCollisionEnter(Collision collision)
    {
        if(collision.gameObject.tag.Equals("Ground")){
            GameObject tempFallOut = Instantiate(rainFallOutPrefab);
            tempFallOut.GetComponent<Renderer>().material = GetComponent<Renderer>().material;
            tempFallOut.transform.position = new Vector3(collision.transform.position.x
            ,collision.transform.position.y+0.5f,
            collision.transform.position.z);
           isGrounding = true;
            Destroy(tempFallOut,0.5f);
            
          
            
        }else if(collision.gameObject.tag.Contains("Player")){
           
             GameObject temp = collision.gameObject.transform.Find("RainHit_ParticleSystem").gameObject;
            if(GetComponent<Renderer>().material.name.Equals("RedRain")){
         

                temp.GetComponent<ParticleSystem>().startColor = GetComponent<Renderer>().material.color; 
            }else{
                
                temp.GetComponent<ParticleSystem>().startColor = collision.gameObject.GetComponent<Renderer>().material.color; 
        
            }
             isGrounding = true;
            temp.GetComponent<ParticleSystem>().Play();
            
             
            
           

            
        }



    }



}
