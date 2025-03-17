using System;
using System.Collections.Generic;
using System.Numerics;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;
using Quaternion = UnityEngine.Quaternion;
using Vector3 = UnityEngine.Vector3;

public class ArchivementManager : MonoBehaviour
{
    [SerializeField] GameObject categoryButtonPrefab;
    [SerializeField] GameObject itemParentPrefab;
    [SerializeField] Transform categoryContent;
    [SerializeField] Transform itemContent;
 
    private GameObject player;
    private ParticleSystem playerEffect;

    public static ArchivementManager Instance;


    [SerializeField] GameObject inspectorCamera_Prefab;

    [SerializeField] GameObject inspectorPanel;


    GameObject inspectorPopUp;

    GameObject showCube;


    
    public enum ItemCategory
    {
        playerSkin,
        skyColor
    }

    public List<Item> items;

    void Awake()
    {
        
        player = GameObject.FindWithTag("Player")?.gameObject;
        
        if (player != null)
        {
            playerEffect = player.GetComponent<PlayerChildren>()?.playerHit_ParticleSystem;
        }
        else
        {
            Debug.LogWarning("Player object not found or missing required components.");
        }

        initButtons();
          
    }

void Start(){
     initItems(0); 
}

        public void ResetSavedItems()
    {
      PlayerPrefs.DeleteAll();
      
        player.GetComponent<Renderer>().material = items[0].material;
        Camera.main.backgroundColor = items[3].color;
      
    }

    void changeItemForObject(int index)
    {
        if (items[index].itemCategory.Equals(ItemCategory.playerSkin))
        {
            player.GetComponent<Renderer>().material = items[index].material;
            PlayerPrefs.SetInt("lastCubeMaterial", index);
        }
        else if (items[index].itemCategory.Equals(ItemCategory.skyColor))
        {
            // Kamera Hintergrundfarbe speichern
            Camera.main.backgroundColor = items[index].color;
            SaveColorToPlayerPrefs("lastCameraColor", items[index].color);
        }
    }

    void initItems(int index)
    {

        
        deleteAllChildren(itemContent);

        for (int i = 0; i < items.Count; i++)
        {
            ItemCategory value = (ItemCategory)index;

            if (items[i].itemCategory == value)
            {
                GameObject temp = Instantiate(itemParentPrefab, itemContent);
                GameObject tempName = temp.transform.Find("ItemName").gameObject;
                GameObject tempUse = temp.transform.Find("ItemUse").gameObject;

                tempName.GetComponent<TMP_Text>().text = items[i].itemName;


                GameObject itemViewer = temp.transform.Find("ItemViewer").gameObject;
             GameObject   currentCamera = Instantiate(inspectorCamera_Prefab,itemViewer.transform);
                
                currentCamera.GetComponent<Camera>().targetTexture = new RenderTexture(1024,1024,64);
                itemViewer.GetComponent<RawImage>().texture = currentCamera.GetComponent<Camera>().targetTexture;


                currentCamera.name = "ItemInspector";
                showCube = currentCamera.transform.Find("Cube").gameObject;


                if(value==ItemCategory.playerSkin){
                 
                 showCube.SetActive(true);
                showCube.GetComponent<MeshRenderer>().material = items[i].material;
        currentCamera.GetComponent<Camera>().backgroundColor = Camera.main.backgroundColor;

        itemViewer.GetComponent<Button>().onClick.AddListener(()=> openInspectorPanel(currentCamera,itemViewer.GetComponent<RawImage>()));


                }else if(value==ItemCategory.skyColor){

                    if(showCube!=null){
                        showCube.gameObject.SetActive(false);
                     
                    }
                    currentCamera.GetComponent<Camera>().backgroundColor = items[i].color;

                }else{
        currentCamera.GetComponent<Camera>().backgroundColor = Camera.main.backgroundColor;
                }
              
                
                           
               

                // Checks if items is unclocked
                bool unlock = PlayerPrefs.GetInt("HighScore") >= items[i].levelToUnlock;
                if (unlock)
                {
                    tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.green;
                    int currentIndex = i;
                    tempUse.GetComponent<UnityEngine.UI.Button>().onClick.AddListener(() => changeItemForObject(currentIndex));
                }
                else
                {
                    tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.red;
                    tempUse.GetComponentInChildren<TMP_Text>().text = "Highscore: " + items[i].levelToUnlock.ToString();
                }
            }
        }
        
    }

    void deleteAllChildren(Transform transform)
    {
        if (transform.childCount > 0)
        {
            for (int i = 0; i < transform.childCount; i++)
            {
                Destroy(transform.GetChild(i).gameObject);
            }
        }
    }

    void initButtons()
    {
        // init category buttons
        for (int i = 0; i < Enum.GetValues(typeof(ItemCategory)).Length; i++)
        {
            GameObject temp = Instantiate(categoryButtonPrefab, categoryContent);

            // Speichere den aktuellen Wert von 'i' in einer lokalen Variablen
            int currentIndex = i;

            // Setze den Text des Buttons
            temp.GetComponentInChildren<TMP_Text>().text = Enum.GetName(typeof(ItemCategory), currentIndex);

            // Füge den Listener hinzu und übergebe 'currentIndex'
            temp.GetComponent<UnityEngine.UI.Button>().onClick.AddListener(() => initItems(currentIndex));
        }
    }

  public void ApplySavedItems()
{
    if (player == null)
    {
        Debug.LogWarning("Player object is null.");
        return;
    }

    // Anwenden des gespeicherten Spieler-Skins
    int lastPlayerSkinIndex = PlayerPrefs.GetInt("lastCubeMaterial", -1);
    if (lastPlayerSkinIndex >= 0 && lastPlayerSkinIndex < items.Count)
    {
        Item skinItem = items[lastPlayerSkinIndex];
        if (skinItem.itemCategory == ItemCategory.playerSkin)
        {
            player.GetComponent<Renderer>().material = skinItem.material;
        }
    }

    // Anwenden der gespeicherten Himmelfarbe
    Color savedSkyColor = LoadColorFromPlayerPrefs("lastCameraColor", Camera.main.backgroundColor);
    Camera.main.backgroundColor = savedSkyColor;
}


    

    public static void SaveColorToPlayerPrefs(string key, Color color)
    {
        PlayerPrefs.SetFloat(key + "_R", color.r);
        PlayerPrefs.SetFloat(key + "_G", color.g);
        PlayerPrefs.SetFloat(key + "_B", color.b);
        PlayerPrefs.SetFloat(key + "_A", color.a); // Falls Alpha benötigt wird
        PlayerPrefs.Save();
    }

    public static Color LoadColorFromPlayerPrefs(string key, Color defaultColor)
    {
        if (PlayerPrefs.HasKey(key + "_R") && PlayerPrefs.HasKey(key + "_G") && PlayerPrefs.HasKey(key + "_B"))
        {
            float r = PlayerPrefs.GetFloat(key + "_R");
            float g = PlayerPrefs.GetFloat(key + "_G");
            float b = PlayerPrefs.GetFloat(key + "_B");
            float a = PlayerPrefs.HasKey(key + "_A") ? PlayerPrefs.GetFloat(key + "_A") : 1.0f; // Alpha optional
            return new Color(r, g, b, a);
        }
        return defaultColor; // Standardfarbe zurückgeben, wenn kein Eintrag vorhanden ist
    }

  
    [System.Serializable]
    public class Item
    {
        public Material material;
        public Color color;
        public GameObject _gameObject;
        public ArchivementManager.ItemCategory itemCategory;
        public string itemName;
        public int levelToUnlock;
    }

public void openInspectorPanel(GameObject tempCamera,RawImage rw){

if(inspectorPopUp==null){
   
inspectorPopUp =  Instantiate(inspectorPanel);

}


GameObject background = inspectorPopUp.transform.Find("Background").gameObject;
GameObject mainPanel = background.transform.Find("MainPanel").gameObject;
GameObject button = mainPanel.transform.Find("Button").gameObject;
button.gameObject.GetComponent<Button>().onClick.AddListener(()=> rotateCube(tempCamera,0,0));
GameObject rawImage = background.transform.Find("RawImage").gameObject;
GameObject left = rawImage.transform.Find("Left").gameObject;
GameObject right = rawImage.transform.Find("Right").gameObject;
GameObject down = rawImage.transform.Find("Down").gameObject;
GameObject up = rawImage.transform.Find("Up").gameObject;
left.GetComponent<Button>().onClick.AddListener(()=> rotateCube(tempCamera,0,45));
right.GetComponent<Button>().onClick.AddListener(()=> rotateCube(tempCamera,0,-45));



up.GetComponent<Button>().onClick.AddListener(()=> rotateCube(tempCamera,45,0));
down.GetComponent<Button>().onClick.AddListener(()=> rotateCube(tempCamera,-45,0));

rawImage.GetComponent<RawImage>().texture = rw.texture;
inspectorPopUp.GetComponent<PopUp>().showPopUp();




}

void rotateCube(GameObject tempCube, int x, int y)
{
    if(tempCube!=null){
GameObject cube = tempCube.transform.Find("Cube").gameObject;

if(x ==0  && y == 0){
cube.transform.rotation = Quaternion.identity;
}else{
cube.transform.Rotate(x, y, 0, Space.World);


    }
    }
    
   





    
}







}
