using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
public class LevelManager : MonoBehaviour
{

GameObject startTop;
[SerializeField] GameObject player;
[SerializeField] GameObject defaultLevel_prefab;
[SerializeField] GameObject logLevel_prefab;
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


 enum LevelPartMode{
defaultMode,
logMode
}

LevelPartMode currentLevelPartMode;

void Awake(){
    currentLevelPartMode = LevelPartMode.defaultMode;
    
         levelUpater();

}





enum GameMode{
    sandMode,iceMode,grassMode
}

    // Start is called before the first frame update
    void Start()
    {
         updateCurrentStartTop();

       
setPlayerToStartTop();
       

       
   
        
    }

    // Update is called once per frame
    void Update()
    {
       updateCurrentStartTop();

      checkGameModes();
     
      
    





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


void FixedUpdate(){
    displayAFKCounter();
}

// Nach Kollision mit NextLevel 
public void createLevelPart(){
    

GameObject temp = Instantiate(getLevelPart(currentLevelPartMode));
levelParts.Add(temp);
currentLevel++;

setCurrentPositionForLevelPart();

levelUpater();
destroyLevelParts();

   

 
}

void setCurrentPositionForLevelPart(){
GameObject lastLevelParentChildren =levelParts[levelParts.Count-2].transform.Find("LevelPart").gameObject;
GameObject nextLevelParentChildren = levelParts[levelParts.Count-1].transform.Find("LevelPart").gameObject;
GameObject nextLevelParent = levelParts[levelParts.Count-1].gameObject;

GameObject tempField = lastLevelParentChildren.transform.Find("Field").gameObject;
CreateField tem = tempField.GetComponent<CreateField>();

nextLevelParent.transform.position = new Vector3(tem.getEndTop().transform.position.x,
lastLevelParentChildren.transform.position.y,lastLevelParentChildren.transform.position.z+tem.z);
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
   setSpeedForLevel(500,2000);
    
    if(currentLevel<10){
           setMaterialForLevelPart(GameMode.grassMode);
    }
    
    if (currentLevel==1){
        currentLevelPartMode = LevelPartMode.logMode;
    }
    
    
if(currentLevel>100){
  int count = Enum.GetValues(typeof(GameMode)).Length;
   int randomMaterial = UnityEngine.Random.Range(0,count);
   
   currentMode = Enum.GetName(typeof(GameMode),randomMaterial).ToString();

    setMaterialForLevelPart(GameMode.grassMode);

}

 
    
    setAFKCounter();
    
}


private void setMaterialForLevelPart(GameMode gm){

    
    gameMode = gm;
    
    currentMode = gm.ToString();
}
private void setSpeedForLevel(float minRainYSpeed,float maxRainYSpeed){
    GameObject tempLevelParent = levelParts[levelParts.Count-1];

tempLevelParent.GetComponent<RainSpawner>().minRainYSpeed = minRainYSpeed;
    tempLevelParent.GetComponent<RainSpawner>().maxRainYSpeed = maxRainYSpeed;
  
}







void groundMaterial(Material material){
    
GameObject currentLevelPart = levelParts[levelParts.Count-1].transform.Find("LevelPart").gameObject;
GameObject currentField = currentLevelPart.transform.Find("Field").gameObject;

    
if(gameMode == GameMode.grassMode){
   currentField.GetComponent<CreateField>().drawField(material);
}else if(gameMode==GameMode.sandMode){

     currentField.GetComponent<CreateField>().drawField(material);

}
else if (gameMode == GameMode.iceMode){
 
 currentField.GetComponent<CreateField>().drawField(material);

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

afkText.text = "Move or Die: " + player.GetComponent<PlayerMovement>().startAfkCounter.ToString("F1");


  

}

// Player wird beim StartTop respawnt
public void setPlayerToStartTop(){

player.transform.position = new Vector3(startTop.transform.position.x,
        startTop.transform.position.y+player.transform.localScale.y,
        startTop.transform.position.z);

    
 
}


// Aktualisiert den aktuellen start vom LevelPart
private void updateCurrentStartTop(){
        if(levelParts[levelParts.Count-1]!=null){
            GameObject temp = levelParts[levelParts.Count-1].transform.Find("LevelPart").gameObject;
            GameObject tempField = temp.transform.Find("Field").gameObject;
            startTop = tempField.GetComponent<CreateField>().startTop;
      

        }
}

GameObject getLevelPart(LevelPartMode levelPartMode){
if(levelPartMode==LevelPartMode.defaultMode){
    return defaultLevel_prefab;
}else if(levelPartMode ==LevelPartMode.logMode){
    return logLevel_prefab;
}
return null;
}

}





