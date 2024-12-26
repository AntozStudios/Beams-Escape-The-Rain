using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class CreatePopUp : MonoBehaviour
{
    [SerializeField] GameObject prefab;
    [SerializeField] Button button;
    [SerializeField] string text;
    private GameObject thisGameobject;

    [SerializeField] Transform parentPanel;
    void Start()
    {
        
        
    }

    // Update is called once per frame
    void Update()
    {
    
        
    }
     public void ClickCreatePopUp(){
        if(thisGameobject==null){
thisGameobject = Instantiate(prefab,parentPanel);
thisGameobject.GetComponent<PopUp>().text.text =text;
        }
    }

   
}
