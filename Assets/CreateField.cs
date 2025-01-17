using System.Collections.Generic;
using UnityEngine;

public class CreateField : MonoBehaviour
{
    [SerializeField] private GameObject topPrefab;
    [SerializeField] private GameObject levelPart;
    [SerializeField] GameObject nextLevel;

    [HideInInspector]public GameObject startTop;

    RainSpawner rainSpawner;

 GameObject pivotObject;
    

    public int x,z;

    public GameObject[,] field;


    
    void Awake(){
        
        field = new GameObject[x,z];
        rainSpawner = GetComponentInParent<RainSpawner>();

         if (topPrefab == null || levelPart == null)
        {
            Debug.LogError("topPrefab oder levelPart ist nicht zugewiesen.");
            return;
        }

               for(int i =0;i<x;i++){
for(int j =0;j<z;j++){

      // Instanz des Prefabs erstellen
         pivotObject = Instantiate(topPrefab, transform);
         pivotObject.name="i: "+i+"j "+j;
        field[i,j] = pivotObject;
        
        float posX = levelPart.transform.position.x - (levelPart.transform.localScale.x / 2) + (pivotObject.transform.localScale.x / 2);
        float posY = levelPart.transform.position.y + (levelPart.transform.localScale.y / 2) + (pivotObject.transform.localScale.y / 2);
        float posZ = levelPart.transform.position.z - (levelPart.transform.localScale.z / 2) + (pivotObject.transform.localScale.z / 2);

        // Position anwenden
        pivotObject.transform.position = new Vector3(posX+(pivotObject.transform.localScale.x*i), posY, posZ+(pivotObject.transform.localScale.z*j));

if(i==x/2 && j==0){
    startTop = pivotObject;

}else if(i==x/2 && j==z-1){
spawnObjectToTile(nextLevel);
}else{
rainSpawner.tops.Add(pivotObject);



}






 


    


        
    }

    }


    }

    private void Start()
    {
  
    }

    void spawnObjectToTile(int i,int j,int a,int b,GameObject from){
       if(i==a&& j==b){
    Instantiate(from,pivotObject.transform).transform.position = new Vector3(pivotObject.transform.position.x,pivotObject.transform.position.y+from.transform.localScale.y,pivotObject.transform.position.z);
    
}
    }
     void spawnObjectToTile(GameObject from){
      
    Instantiate(from,pivotObject.transform).transform.position = new Vector3(pivotObject.transform.position.x,pivotObject.transform.position.y+from.transform.localScale.y,pivotObject.transform.position.z);
    

    }

    public void drawField(Material material){
        for(int i =0;i<x;i++){
            for(int j =0;j<z;j++){
            field[i,j].GetComponent<Renderer>().material = material;
        }
        }
    }

    public GameObject getEndTop(){
        return field[x/2,z-1];
    }
}
