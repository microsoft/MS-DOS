import java.util.*;
class chefSum
{
    public static void main(String [] args)
    {
        Scanner sc=new Scanner(System.in);
        int n=sc.nextInt();
        int v[]=new int[n];
        for(int i=0;i<n;i++)
        {
            int x=sc.nextInt();
            int arr[]=new int[x];
            for(int j=0;j<x;j++)
            arr[j]=sc.nextInt();
            int min=arr[0];
            int index=0;
            for(int j=0;j<x;j++)
            {
                if(arr[j]<min)
                {
                    min=arr[j];
                    index=j;
                }
            }
            v[i]=index+1;
            
            
            
        }
        for(int l=0;l<n;l++)
        System.out.println(v[l]);
        
        
        
        
        
        
        
    }
}
                    
                
