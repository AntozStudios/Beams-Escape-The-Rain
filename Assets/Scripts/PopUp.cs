using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PopUp : MonoBehaviour
{
  



    private Animator animator;
    public TMP_Text content;
    public Button yesButton,noButton,nextButton;



    
    void Awake(){
      animator = GetComponentInChildren<Animator>();
     
    }

    void Start(){
     
    }
public void showPopUp(){
  animator.SetTrigger("start");
  
}
   
public void hidePopUp(){

  animator.SetTrigger("hide");

  
}
   void Update(){
    
   }

    





}
