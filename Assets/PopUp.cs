using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PopUp : MonoBehaviour
{
    [SerializeField] Button exitButton;
    [SerializeField] GameObject thisPopUp;
    [HideInInspector]public TMP_Text text;

      GameObject player;
    
void Awake(){
   player = GameObject.FindWithTag("Player").gameObject;
   player.GetComponent<PlayerMovement>().canMove = false;
}
void OnDestroy(){
player.GetComponent<PlayerMovement>().canMove = true;
}


    public void DestroyPopUp(){
        Destroy(thisPopUp);
        
    }

    void Update(){
    
    
    }
}
