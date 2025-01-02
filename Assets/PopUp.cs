using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class PopUp : MonoBehaviour
{
    [SerializeField] Button exitButton;

    public TMP_Text text;


    private Animator animator;



    
    void Awake(){
      animator = GetComponentInChildren<Animator>();
     
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
