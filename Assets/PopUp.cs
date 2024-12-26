using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

public class PopUp : MonoBehaviour
{
    [SerializeField] Button exitButton;
    [HideInInspector]public TMP_Text text;



    public void DestroyPopUp(){
        Destroy(this.gameObject);
    }
}
