using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.UI;

public class CreatePopUp : MonoBehaviour
{
    public GameObject prefab;
    
    

  public int index;
    [SerializeField] string text;
    private GameObject thisGameobject;
   

    void Awake(){





     
    }
    
 
    
    void Start()
    {
        
         
    }

    // Update is called once per frame
    void Update()
    {
    

        
    }
     public void ClickCreatePopUp(){
        if(thisGameobject==null){
thisGameobject = Instantiate(prefab);
if(text.Length>0){
thisGameobject.GetComponent<PopUp>().text.text =text;
}

        }else{
          showPopUp();
        }
        
    }

  

   public void showPopUp(){
     
        thisGameobject.GetComponent<PopUp>().showPopUp();

   }

   
}
