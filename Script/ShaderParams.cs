using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ShaderParams : MonoBehaviour
{
    public Transform headBoneTransform;
    public Transform headForwardTransform;
    public Transform headRightTransform;
    
    private Renderer[] allRenderers;
    
    private int headCenterID = Shader.PropertyToID("_HeadCenter");
    private int headRightID = Shader.PropertyToID("_HeadRight");
    private int headForwardID = Shader.PropertyToID("_HeadForward");
    
    #if UNITY_EDITOR
    private void OnValidate()
    {
        Update();
    }
    #endif

    void Update()
    {
        if (allRenderers ==null)
        {
            allRenderers = GetComponentsInChildren<Renderer>(true);
        }

        for (int i = 0; i < allRenderers.Length; i++)
        {
            Renderer r = allRenderers[i];
            foreach (Material mat in r.sharedMaterials)
            {
                if (mat.shader)
                {
                    if (mat.shader.name == "Foth/Aglina")
                    {
                        mat.SetVector(headCenterID,headBoneTransform.position);
                        mat.SetVector(headForwardID, headForwardTransform.position);
                        mat.SetVector(headRightID, headRightTransform.position);
                    }
                }
            }
            
        }
    }
}
