using System;
using UnityEngine;

public class FollowPlayer : MonoBehaviour
{
    [HideInInspector]public float followSpeed;
    [SerializeField] GameObject player;

    Vector3 initPosCamera;
    Vector3 initPosPlayer;
    float cameraPosZ;
    float playerPosZ;

    float cameraPosX;
    float playerPosX;

    public bool doFollowPlayer;

    void Start(){
                initPosCamera = Camera.main.transform.position;
        initPosPlayer = player.transform.position;
        cameraPosZ = Mathf.Abs(initPosCamera.z);
        playerPosZ = Mathf.Abs(initPosPlayer.z);
        cameraPosX = Mathf.Abs(initPosCamera.x);
        playerPosX = Mathf.Abs(initPosPlayer.x);
    }


    void Update()
    {
        if (doFollowPlayer)
        {
            // Zielposition entlang der Z-Achse
            float targetZ = player.transform.position.z + playerPosZ - cameraPosZ;

            // Interpolierte Kamera-Position
            float smoothZ = Mathf.Lerp(Camera.main.transform.position.z, targetZ, followSpeed * Time.deltaTime);


             // Zielposition entlang der Z-Achse
            float targetX = player.transform.position.x + playerPosX - cameraPosX;

            // Interpolierte Kamera-Position
            float smoothX = Mathf.Lerp(Camera.main.transform.position.x, targetX, followSpeed * Time.deltaTime);

            Camera.main.transform.position = new Vector3(
                smoothX,
                Camera.main.transform.position.y,
                smoothZ
            );
        }else {
            
                
                 // Kamera klebt fest am Spieler
            Camera.main.transform.position = new Vector3(
                player.transform.position.x + playerPosX - cameraPosX,
                Camera.main.transform.position.y,
                player.transform.position.z + playerPosZ - cameraPosZ
            );

        }
            
    }
}
