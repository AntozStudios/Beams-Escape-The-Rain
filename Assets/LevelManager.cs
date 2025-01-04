using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using TMPro;
using Unity.Services.Authentication.PlayerAccounts.Samples;
using UnityEngine;

public class LevelManager : MonoBehaviour
{

GameObject startTop;
[SerializeField] GameObject player;
[SerializeField] GameObject LevelPartPrefab;
[SerializeField] GameObject deathParent;




[HideInInspector] public bool gameStarted;
public List<GameObject> levelParts;

[SerializeField] TMP_Text afkText;

string currentMode;



public int currentLevel;

[SerializeField] 

 Material sandMaterial,iceMaterial,grassMaterial;


GameMode gameMode;
[SerializeField]


void Awake(){
    
    
         levelUpater();
updateCurrentStartTop();
}





enum GameMode{
    sandMode,iceMode,grassMode
}

    // Start is called before the first frame update
    void Start()
    {
setPlayerToStartTop();
       

       
   
        
    }

    // Update is called once per frame
    void Update()
    {
       updateCurrentStartTop();

      checkGameModes();
     
      
    


displayAFKCounter();


    }   

void checkGameModes(){
      if(gameMode == GameMode.grassMode ){
            groundMaterial(grassMaterial);
        }else if(gameMode == GameMode.iceMode){
            groundMaterial(iceMaterial);
        }else if(gameMode == GameMode.sandMode){
            groundMaterial(sandMaterial);
    }

}



public void createLevelPart(){
    

GameObject temp = Instantiate(LevelPartPrefab);
levelParts.Add(temp);
currentLevel++;
GameObject lastLevelParentChildren =levelParts[levelParts.Count-2].transform.Find("LevelPart").gameObject;
GameObject nextLevelParentChildren = levelParts[levelParts.Count-1].transform.Find("LevelPart").gameObject;
GameObject nextLevelParent = levelParts[levelParts.Count-1].gameObject;

nextLevelParent.transform.position = new Vector3(lastLevelParentChildren.transform.position.x,
lastLevelParentChildren.transform.position.y,lastLevelParentChildren.transform.position.z+nextLevelParentChildren.transform.localScale.z);
levelUpater();
destroyLevelParts();

   

 
}

public void destroyLevelParts()
{
    if (levelParts.Count > 3)
    {
        Destroy(levelParts[0]);
        levelParts.RemoveAt(0);
    }
    if (deathParent.transform.childCount > 3)
    {
        GameObject temp = deathParent.transform.GetChild(0).gameObject;
        if(temp!= null &&temp.name.Equals("GlowEffectParent")){
            Destroy(deathParent.transform.GetChild(0).gameObject);
        }
        
   
    }
}



void levelUpater(){
    if(currentLevel>=0 && currentLevel<=25){
       levelSettings(2000,8000,GameMode.grassMode,false);
       currentMode = GameMode.grassMode.ToString();
    
    }else  if(currentLevel>25 && currentLevel<=50){
        levelSettings(3000,9000,GameMode.iceMode,false);
        currentMode = GameMode.iceMode.ToString();
    }
    else  if(currentLevel>50 && currentLevel<=100){
        levelSettings(4000,10000,GameMode.sandMode,false);
        currentMode = GameMode.sandMode.ToString();
    }
    else{


   int count = Enum.GetValues(typeof(GameMode)).Length;
   int randomMaterial = UnityEngine.Random.Range(0,count);
   Debug.Log(randomMaterial);
   Debug.Log(currentMode);
   currentMode = Enum.GetName(typeof(GameMode),randomMaterial).ToString();

    levelSettings(5000,10000,(GameMode)randomMaterial,false);
    }
    setAFKCounter();
    
}

private void levelSettings(float minRainYSpeed,float maxRainYSpeed,GameMode gm,bool random){
    if(!random){
levelParts[levelParts.Count-1].GetComponent<RainSpawner>().minRainYSpeed = minRainYSpeed;
    levelParts[levelParts.Count-1].GetComponent<RainSpawner>().maxRainYSpeed = maxRainYSpeed;
    gameMode = gm;
    }else{
        levelParts[levelParts.Count-1].GetComponent<RainSpawner>().minRainYSpeed = minRainYSpeed;
    levelParts[levelParts.Count-1].GetComponent<RainSpawner>().maxRainYSpeed = maxRainYSpeed;
    gameMode = gm;
    }
    
}





void groundMaterial(Material material){
    

foreach(GameObject g in levelParts[levelParts.Count-1].GetComponent<LevelMaterial>().tops){
    
if(gameMode == GameMode.grassMode){
    g.GetComponent<Renderer>().material = grassMaterial;
}else if(gameMode==GameMode.sandMode){

g.GetComponent<Renderer>().material = sandMaterial;

}
else if (gameMode == GameMode.iceMode){
    g.GetComponent<Renderer>().material = iceMaterial;


    }
    
    



}
}



public void setAFKCounter(){
if(currentMode.Equals(GameMode.grassMode.ToString())){
player.GetComponent<PlayerMovement>().startAfkMax =6;

}else if(currentMode.Equals(GameMode.iceMode.ToString())){
    player.GetComponent<PlayerMovement>().startAfkMax =4;
}
else if(currentMode.Equals(GameMode.sandMode.ToString())){
    player.GetComponent<PlayerMovement>().startAfkMax =2;
}
}



void displayAFKCounter(){
    if(player.GetComponent<PlayerMovement>().startAFKTimer && player.GetComponent<PlayerMovement>().verticalMoves>=1){
afkText.text = "Move or Die: "+(int)player.GetComponent<PlayerMovement>().startAfkCounter;
}else{
    afkText.text = "";
}
}


public void setPlayerToStartTop(){
 player.transform.position = new Vector3(startTop.transform.position.x,
        startTop.transform.position.y+player.transform.localScale.y,
        startTop.transform.position.z);
}

private void updateCurrentStartTop(){
        if(levelParts[levelParts.Count-1]!=null){
            GameObject temp = levelParts[levelParts.Count-1].transform.Find("LevelPart").gameObject;
            GameObject tempRainTop = temp.transform.Find("RainTop").gameObject;
            GameObject tempLane = tempRainTop.transform.Find("Lane4 (Middle)").gameObject;
            startTop = tempLane.transform.Find("Top1").gameObject;
      

        }
}



}





