using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;



public class ArchivementManager : MonoBehaviour
{
    
    [SerializeField] GameObject categoryButtonPrefab;
    [SerializeField] GameObject itemParentPrefab;

    [SerializeField] Transform categoryContent;
    [SerializeField] Transform itemContent;


    private GameObject player;
    private Camera playerCamera;
    private ParticleSystem playerEffect;

private static ArchivementManager instance;


    
    public enum ItemCategory{
        playerSkin,
        skyColor
    }


[SerializeField] List<Item> items;
    

    void Awake(){
    if (instance == null) {
        instance = this;
    } else {
        Destroy(gameObject);
    }
    DontDestroyOnLoad(gameObject); // Damit der Manager nicht beim Szenenwechsel gelöscht wird
        initAllItems();
        categoryContent.GetChild(0).GetComponent<Button>().onClick.AddListener(()=>initAllItems());
        player = GameObject.FindWithTag("Player").gameObject;
        playerCamera = Camera.main;
        playerEffect = player.GetComponent<PlayerChildren>().playerHit_ParticleSystem;
    
        initButtons();

        
    }

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

       
    }

    void changeItemForObject(int index){
        if(items[index].itemCategory.Equals(ItemCategory.playerSkin)){
            player.GetComponent<Renderer>().material = items[index].material;
            PlayerPrefs.SetInt("lastCubeMaterial",index);
        }
        else if(items[index].itemCategory.Equals(ItemCategory.skyColor)){
            playerCamera.backgroundColor = items[index].color;
            PlayerPrefs.SetFloat("lastCameraColorR",items[index].color.r);
            PlayerPrefs.SetFloat("lastCameraColorG",items[index].color.g);
            PlayerPrefs.SetFloat("lastCameraColorB",items[index].color.b);
        }
    }
    
    void initItems(int index){
deleteAllChildren(itemContent);

for(int i =0;i<items.Count;i++){
  ItemCategory value = (ItemCategory) index;
  
    if(items[i].itemCategory==value){
        GameObject temp =Instantiate(itemParentPrefab, itemContent);
        GameObject tempName = temp.transform.Find("ItemName").gameObject;
        GameObject tempUse = temp.transform.Find("ItemUse").gameObject;
        

        tempName.GetComponent<TMP_Text>().text = items[i].itemName;
       

       bool unlock =PlayerPrefs.GetInt("HighScore")>= items[i].levelToUnlock;
        if(unlock){
        tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.green;
        int currentIndex = i;
          tempUse.GetComponent<UnityEngine.UI.Button>().onClick.AddListener(()=> changeItemForObject(currentIndex));
        
    

        }else{
             tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.red;
             tempUse.GetComponentInChildren<TMP_Text>().text = "Highscore: "+items[i].levelToUnlock.ToString();
        }
       
           
    }
    
  
}


    }

    void deleteAllChildren(Transform transform){
        if(transform.childCount>0){
            for(int i =0;i<transform.childCount;i++){
                Destroy(transform.GetChild(i).gameObject);
            }
        }
            
    }

  void initButtons(){
    for(int i = 0; i < Enum.GetValues(typeof(ItemCategory)).Length; i++){
        GameObject temp = Instantiate(categoryButtonPrefab, categoryContent);
        
        // Speichere den aktuellen Wert von 'i' in einer lokalen Variablen
        int currentIndex = i;
        
        // Setze den Text des Buttons
        temp.GetComponentInChildren<TMP_Text>().text = Enum.GetName(typeof(ItemCategory), currentIndex);
        
        // Füge den Listener hinzu und übergebe 'currentIndex'
        temp.GetComponent<UnityEngine.UI.Button>().onClick.AddListener(() => initItems(currentIndex));
    }
}

void initAllItems(){
    deleteAllChildren(itemContent);
    for(int i =0;i<items.Count;i++){
 GameObject temp =Instantiate(itemParentPrefab, itemContent);
        GameObject tempName = temp.transform.Find("ItemName").gameObject;
        GameObject tempUse = temp.transform.Find("ItemUse").gameObject;
        

        tempName.GetComponent<TMP_Text>().text = items[i].itemName;
       

       bool unlock =PlayerPrefs.GetInt("HighScore")>= items[i].levelToUnlock;
        if(unlock){
        tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.green;
        int currentIndex = i;
          tempUse.GetComponent<UnityEngine.UI.Button>().onClick.AddListener(()=> changeItemForObject(currentIndex));

    

        }else{
             tempUse.GetComponent<UnityEngine.UI.Button>().image.color = Color.red;
             tempUse.GetComponentInChildren<TMP_Text>().text = "Highscore: "+items[i].levelToUnlock.ToString();
        }
    }
      
       
}

public static void ApplySavedItems(GameObject player, Camera playerCamera) {
    
if(PlayerPrefs.GetInt("lastCubeMaterial")>0){
 player.GetComponent<Renderer>().material = instance.items[PlayerPrefs.GetInt("lastCubeMaterial")].material;
}
  

    Color tempColor = new Color(
        PlayerPrefs.GetFloat("lastCameraColorR"),
        PlayerPrefs.GetFloat("lastCameraColorG"),
        PlayerPrefs.GetFloat("lastCameraColorB")
    );
    playerCamera.backgroundColor = tempColor;
}





[System.Serializable]
    class Item{
       public Material material;
       public Color color;
       public GameObject _gameObject;


       public ArchivementManager.ItemCategory itemCategory;

      
        public string itemName;

        public int levelToUnlock;
      



    }




}
