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

    [SerializeField] bool destroyObject;

      GameObject player;
    
void Awake(){
   player = GameObject.FindWithTag("Player").gameObject;
   player.GetComponent<PlayerMovement>().canMove = false;
}

void Start(){
   show();
}
void OnDestroy(){
    if(!destroyObject){
player.GetComponent<PlayerMovement>().canMove = true;
    }

}


    public void DestroyPopUp(){
        
      GetComponentInChildren<Animator>().SetTrigger("hide");
      
       
        
    }

    void Update(){
    if(!destroyObject){
 if(GetComponentInChildren<Animator>().GetCurrentAnimatorStateInfo(0).IsName("PopUpIdle")){
player.GetComponent<PlayerMovement>().canMove = false;
    }else{
        player.GetComponent<PlayerMovement>().canMove = true;
    }
    }
   

    if(destroyObject){
        if(GetComponentInChildren<Animator>().GetCurrentAnimatorStateInfo(0).IsName("PopUpExit")){
            Destroy(gameObject);
        }
    }
    
    
    }

    public void show(){
        GetComponentInChildren<Animator>().SetTrigger("start");
    }
}
