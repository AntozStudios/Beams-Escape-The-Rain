using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PopUp : MonoBehaviour
{
    
    [SerializeField] Button exitButton;

    [HideInInspector]public TMP_Text text;

    [SerializeField] bool destroyObject;

      GameObject player;
    
void Awake(){
   player = GameObject.FindWithTag("Player").gameObject;
   if(destroyObject){
player.GetComponent<PlayerMovement>().canMove = false;
   }
   
   
}


void OnDestroy(){
    if(destroyObject && player!=null){

player.GetComponent<PlayerMovement>().canMove = true;
    }

}


    public void DestroyPopUp(){
        
      GetComponentInChildren<Animator>().SetTrigger("hide");
      
       
        
    }

    void Update(){
{
  }

    
    }

    public void show(){
        GetComponentInChildren<Animator>().SetTrigger("start");
    }
}
