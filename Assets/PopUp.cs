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

    [SerializeField] bool dontDestroy;

      GameObject player;
    
void Awake(){
   player = GameObject.FindWithTag("Player").gameObject;
   player.GetComponent<PlayerMovement>().canMove = false;
}

void Start(){
   GetComponentInChildren<Animator>().SetTrigger("start");
   show();
}
void OnDestroy(){
    if(dontDestroy){
player.GetComponent<PlayerMovement>().canMove = true;
    }

}


    public void DestroyPopUp(){
        if(dontDestroy){
 Destroy(thisPopUp);
        }else{
      GetComponentInChildren<Animator>().SetTrigger("hide");
        }
       
        
    }

    void Update(){
    if(!GetComponentInChildren<Animator>().GetCurrentAnimatorStateInfo(0).IsName("PopUpIdle")){
player.GetComponent<PlayerMovement>().canMove = false;
    }
    
    }

    public void show(){
        GetComponentInChildren<Animator>().SetTrigger("start");
    }
}
