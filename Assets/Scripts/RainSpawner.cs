using System.Collections.Generic;
using Unity.VisualScripting;
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

   public List<GameObject> tops;
   public List<GameObject> tops_material;
  
    

void Awake(){
 
   



}
  
    void Start()
    {
     
     levelManager = GameObject.Find("LevelManager").GetComponent<LevelManager>();  

Random.InitState(levelManager.currentLevel);
Debug.Log(levelManager.currentLevel);
    rainDrops = new GameObject[tops.Count];

    

       

 
 for(int i =0;i<tops.Count;i++){
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
void checkGrounding(){
    for(int i =0;i<rainDrops.Length;i++){
    if(rainDrops[i].GetComponent<RainCollision>().isGrounding){
        rainDrops[i].transform.position = rainDrops[i].GetComponent<RainCollision>().initPos;
       rainDrops[i].GetComponent<RainBehaviour>().isRaining = false;
    groundedRainCounter++;
       rainDrops[i].GetComponent<RainCollision>().isGrounding = false;
    }
}
if(groundedRainCounter>=rainDrops.Length){
    for(int i =0;i<rainDrops.Length;i++){
        rainDrops[i].GetComponent<RainBehaviour>().isRaining = true;
       groundedRainCounter=0;
        
       
    
}
}

}



}