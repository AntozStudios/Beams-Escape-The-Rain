using System;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using Vector3 = UnityEngine.Vector3;
using Random = UnityEngine.Random;
using Unity.VisualScripting;

public class LevelManager : MonoBehaviour
{
    GameObject startTop;
    [SerializeField] GameObject player;
    [SerializeField] GameObject defaultLevel_prefab;
    [SerializeField] GameObject logLevel_prefab;
    [SerializeField] GameObject deathParent;
    [SerializeField] TMP_Text afkText;
    [SerializeField] Material sandMaterial, iceMaterial, grassMaterial;

    enum LevelPartDirection { BACK, LEFT, RIGHT }
    enum GameMode { sandMode, iceMode, grassMode }
    enum LevelPartMode { defaultMode, logMode }

    int directionCounter;

    [HideInInspector] public bool gameStarted;
    public List<GameObject> levelParts = new List<GameObject>();

    GameMode gameMode;

    LevelPartMode currentLevelPartMode;
    string currentMode;
    public int currentLevel = 0;

    void Start()
    {
        if (levelParts.Count == 0)
        {
            GameObject temp = Instantiate(getLevelPart(currentLevelPartMode));
            Destroy(temp.GetComponentInChildren<Animator>());
            levelParts.Add(temp);
        }
        levelUpdater();
        updateCurrentStartTop();
        setPlayerToStartTop();
    }

    void Update()
    {
        
        updateCurrentStartTop();
        checkGameModes();

     
    }

    void FixedUpdate()
    {
        displayAFKCounter();
    }

    void checkGameModes()
    {
        if (gameMode == GameMode.grassMode) groundMaterial(grassMaterial);
        else if (gameMode == GameMode.iceMode) groundMaterial(iceMaterial);
        else groundMaterial(sandMaterial);
    }

 public void createLevelPart()
{
    currentLevel++;

    // Erstelle den LevelPart basierend auf dem aktuellen Modus
    GameObject temp = Instantiate(defaultLevel_prefab);
    levelParts.Add(temp);

    // Update LevelPart Position und andere Einstellungen
    levelUpdater(); 



    destroyLevelParts();
    directionCounter++;
}


 void setCurrentPositionForLevelPart(LevelPartDirection levelPartDirection)
{
    if (levelParts.Count > 1)
    {
        GameObject lastParent_LevelPart = levelParts[^2];
        GameObject lastChild = lastParent_LevelPart.transform.Find("LevelPart").gameObject;
        GameObject currentParent_LevelPart = levelParts[^1];
        GameObject currentChild = currentParent_LevelPart.transform.Find("LevelPart").gameObject;

       
        // Berechnung der Bounds für die genaue Größe
        Bounds lastBounds = GetObjectBounds(lastChild);
        Bounds currentBounds = GetObjectBounds(currentChild);

        Vector3 newPos = lastChild.transform.position;

        switch (levelPartDirection)
        {
            case LevelPartDirection.BACK:
                newPos.z += (lastBounds.extents.z + currentBounds.extents.z);
                break;
            case LevelPartDirection.RIGHT:
                newPos.x += (lastBounds.extents.x + currentBounds.extents.x);
                break;
            case LevelPartDirection.LEFT:
                newPos.x -= (lastBounds.extents.x + currentBounds.extents.x);
                break;
        }
       

    
        currentParent_LevelPart.transform.position = newPos;
    }
}

// Methode zur exakten Berechnung der Größe eines GameObjects inklusive Rotation
Bounds GetObjectBounds(GameObject obj)
{
    Renderer[] renderers = obj.GetComponentsInChildren<Renderer>();
    if (renderers.Length == 0)
        return new Bounds(obj.transform.position, Vector3.zero);

    Bounds bounds = renderers[0].bounds;
    foreach (Renderer r in renderers)
    {
        bounds.Encapsulate(r.bounds);
    }

    return bounds;
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
            if (temp != null && temp.name.Equals("GlowEffectParent"))
            {
                Destroy(temp);
            }
        }
    }

void levelUpdater()
{
    setSpeedForLevel(500, 2000);
    

    if (levelParts.Count == 0) {
        Debug.LogError("Keine LevelParts vorhanden!");
        return;
    }

    CreateField createField = levelParts[^1].GetComponentInChildren<CreateField>();
     if (createField == null) {
        Debug.LogError("CreateField nicht gefunden!");
        return;
    }

    createField.spawnObject(CreateField.SpawnObject.BACK, GameObject_Container.Instance.nextLevel);
    currentLevelPartMode = LevelPartMode.defaultMode;
   if(currentLevel==0){
     setMaterialForLevelPart(GameMode.grassMode);
   }else{
  int max = Enum.GetValues(typeof(GameMode)).Length+1;
setMaterialForLevelPart((GameMode)Random.Range(0, max));

   }
    setCurrentPositionForLevelPart(LevelPartDirection.BACK);
   
    

    
   

   
            

    
   
    setAFKCounter();
}



    void setMaterialForLevelPart(GameMode gm)
    {
        gameMode = gm;
        currentMode = gm.ToString();
    }

    void setSpeedForLevel(float minRainYSpeed, float maxRainYSpeed)
    {
        RainSpawner rainSpawner = levelParts[^1].GetComponent<RainSpawner>();
        rainSpawner.minRainYSpeed = minRainYSpeed;
        rainSpawner.maxRainYSpeed = maxRainYSpeed;
    }

    void groundMaterial(Material material)
    {
        CreateField createField = levelParts[^1].transform.Find("LevelPart/Field").GetComponent<CreateField>();
        createField.drawField(material);
    }

    public void setAFKCounter()
    {
        PlayerMovement playerMovement = player.GetComponent<PlayerMovement>();

        if (currentMode == GameMode.grassMode.ToString()) playerMovement.startAfkMax = 6;
        else if (currentMode == GameMode.iceMode.ToString()) playerMovement.startAfkMax = 4;
        else playerMovement.startAfkMax = 2;
    }

    void displayAFKCounter()
    {
        if(player.GetComponent<PlayerMovement>().startAFKTimer && gameStarted){
            afkText.gameObject.SetActive(true);
afkText.text = "Move or Die: " + player.GetComponent<PlayerMovement>().startAfkCounter.ToString("F1");
        }else{
afkText.text = "";
     afkText.gameObject.SetActive(false);
          
        }
        
    }

    public void setPlayerToStartTop()
    {
        player.transform.position = new Vector3(
            startTop.transform.position.x,
            startTop.transform.position.y + player.transform.localScale.y,
            startTop.transform.position.z
        );
    }

    void updateCurrentStartTop()
    {
        if (levelParts.Count > 0)
        {
            startTop = levelParts[^1].transform.Find("LevelPart/Field").GetComponent<CreateField>().startTop;
        }
    }

    GameObject getLevelPart(LevelPartMode levelPartMode)
    {
        return levelPartMode == LevelPartMode.defaultMode ? defaultLevel_prefab : logLevel_prefab;
    }
}
