using System;
using UnityEngine;

public class CameraConfig : MonoBehaviour
{
   
    public CameraSettings[] cameraSettings;
    public enum CameraMode{
        isometric,
        isometric_2d
    }
    public CameraMode currentCameraMode;

    
void Awake(){
    currentCameraMode = CameraMode.isometric;
    setConfig(currentCameraMode);
}
    void setConfig(CameraMode cameraMode){
        Camera.main.transform.position = cameraSettings[(int) cameraMode].pos;
        Camera.main.transform.position = cameraSettings[(int) cameraMode].rotation;
    }

[Serializable]
    public class CameraSettings{
        [SerializeField] string name;
        public Vector3 pos;
        public Vector3 rotation;

    }
}
