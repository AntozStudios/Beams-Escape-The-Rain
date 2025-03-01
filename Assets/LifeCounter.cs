using TMPro;
using UnityEngine;

public class LifeCounter : MonoBehaviour
{
   private char symbol ='.';
   TMP_Text lifeText;
   
void Awake(){
    lifeText = GetComponent<TMP_Text>();
}
   public void change(int lifeCount){
      if(lifeText!=null){
lifeText.text="";
   for(int i =0;i<lifeCount;i++){
lifeText.text +=symbol;
   }

      }

   }
}
