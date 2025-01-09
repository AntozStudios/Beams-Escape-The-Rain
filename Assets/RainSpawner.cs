using System.Collections.Generic;
using Unity.VisualScripting;
using Unity.VisualScripting.FullSerializer;
using UnityEngine;
public class RainSpawner : MonoBehaviour
{
    
    [SerializeField] GameObject rainPrefab;
    

private LevelManager levelManager;

    public float minRainYSpeed;
    public float maxRainYSpeed;

    private int groundedRainCounter;
    public GameObject[] rainDrops;
    
    

    public float height;


public bool stopAndDestroyRaindrops;


  


    
   [SerializeField] GameObject[] tops;
    

void Awake(){
    levelManager = GameObject.Find("LevelManager").GetComponent<LevelManager>();   
    rainDrops = new GameObject[tops.Length];
    

}
  
    void Start()
    {
     
     Random.InitState(levelManager.currentLevel);

 
 for(int i =0;i<tops.Length;i++){

GameObject temp = Instantiate(rainPrefab,transform);
    rainDrops[i] = temp;
    
    
 rainDrops[i].GetComponent<Renderer>().material = rainDrops[i].GetComponent<RainBehaviour>().materials[rainDrops[i].GetComponent<RainBehaviour>().getRandomMaterial()];

    rainDrops[i].GetComponent<RainBehaviour>().ySpeed = Random.Range(minRainYSpeed,maxRainYSpeed);

    rainDrops[i].transform.position = new Vector3(tops[i].transform.position.x,height,tops[i].transform.position.z);
    
    

 }




    



        
    }

   
void Update(){


checkGrounding();





}

public void destroyAndStop(){

}
void checkGrounding(){
    for(int i =0;i<rainDrops.Length;i++){
        if(rainDrops[i]!=null && rainDrops[i].GetComponent<RainBehaviour>()!=null) {
if(rainDrops[i].GetComponent<RainCollision>().isGrounding){
        rainDrops[i].transform.position = rainDrops[i].GetComponent<RainCollision>().initPos;
       rainDrops[i].GetComponent<RainBehaviour>().isRaining = false;
    groundedRainCounter++;
       rainDrops[i].GetComponent<RainCollision>().isGrounding = false;
       if(stopAndDestroyRaindrops){
        Destroy(rainDrops[i]);
       }
    }
            
        }
        
    
}
if(groundedRainCounter>=rainDrops.Length){
    for(int i =0;i<rainDrops.Length;i++){
        if(rainDrops[i]!=null && rainDrops[i].GetComponent<RainBehaviour>()!=null){
     rainDrops[i].GetComponent<RainBehaviour>().isRaining = true;
       groundedRainCounter=0;
        }
   
        
       
    
}
}


}


}