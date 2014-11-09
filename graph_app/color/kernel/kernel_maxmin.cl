/************************************************************************************\
 *                                                                                  *
 * Copyright � 2014 Advanced Micro Devices, Inc.                                    *
 * All rights reserved.                                                             *
 *                                                                                  *
 * Redistribution and use in source and binary forms, with or without               *
 * modification, are permitted provided that the following are met:                 *
 *                                                                                  *
 * You must reproduce the above copyright notice.                                   *
 *                                                                                  *
 * Neither the name of the copyright holder nor the names of its contributors       *   
 * may be used to endorse or promote products derived from this software            *
 * without specific, prior, written permission from at least the copyright holder.  *
 *                                                                                  *
 * You must include the following terms in your license and/or other materials      *
 * provided with the software.                                                      * 
 *                                                                                  *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"      *
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE        *
 * IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, AND FITNESS FOR A       *
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER        *
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,         *
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  * 
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS      *
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN          *
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING  *
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY   *
 * OF SUCH DAMAGE.                                                                  *
 *                                                                                  *
 * Without limiting the foregoing, the software may implement third party           *  
 * technologies for which you must obtain licenses from parties other than AMD.     *  
 * You agree that AMD has not obtained or conveyed to you, and that you shall       *
 * be responsible for obtaining the rights to use and/or distribute the applicable  * 
 * underlying intellectual property rights related to the third party technologies. *  
 * These third party technologies are not licensed hereunder.                       *
 *                                                                                  *
 * If you use the software (in whole or in part), you shall adhere to all           *        
 * applicable U.S., European, and other export laws, including but not limited to   *
 * the U.S. Export Administration Regulations ("EAR"�) (15 C.F.R Sections 730-774),  *
 * and E.U. Council Regulation (EC) No 428/2009 of 5 May 2009.  Further, pursuant   *
 * to Section 740.6 of the EAR, you hereby certify that, except pursuant to a       *
 * license granted by the United States Department of Commerce Bureau of Industry   *
 * and Security or as otherwise permitted pursuant to a License Exception under     *
 * the U.S. Export Administration Regulations ("EAR"), you will not (1) export,     *
 * re-export or release to a national of a country in Country Groups D:1, E:1 or    * 
 * E:2 any restricted technology, software, or source code you receive hereunder,   * 
 * or (2) export to Country Groups D:1, E:1 or E:2 the direct product of such       *
 * technology or software, if such foreign produced direct product is subject to    * 
 * national security controls as identified on the Commerce Control List (currently * 
 * found in Supplement 1 to Part 774 of EAR).  For the most current Country Group   * 
 * listings, or for additional information about the EAR or your obligations under  *
 * those regulations, please refer to the U.S. Bureau of Industry and Security's    *
 * website at http://www.bis.doc.gov/.                                              *
 *                                                                                  *
\************************************************************************************/

#define BIG_NUM 999999

/**
 * @brief   color kernel 1
 * @param   row         CSR pointer array
 * @param   col         CSR column array 
 * @param   node_value  Vertex value array 
 * @param   color_array Color value array
 * @param   stop        Termination variable 
 * @param   max_d       Max array
 * @param   max_d       Min array
 * @param   color       Current color label 
 * @param   num_nodes   Number of vertices
 * @param   num_edges   Number of edges
 */
__kernel  void color( __global int *row, 
                      __global int *col, 
                      __global int *node_value,
                      __global int *color_array,
                      __global int *stop, 
                      __global int *max_d,
                      __global int *min_d,
                         const int color,
                         const int num_nodes,
				         const int num_edges)
{
    //get my workitem id
    int tid = get_global_id(0);

    if (tid < num_nodes){
       //if the vertex is not colored
	   if(color_array[tid] == -1){

	      //get the start and end pointers for the neighbor list
	      int start = row[tid];
	      int end;
          if (tid + 1 < num_nodes)
        	end = row[tid + 1] ;
          else
        	end = num_edges;

	      int maximum = -1;
          int minimum  = BIG_NUM;
          //navigate the neighborlist  
	      for(int edge = start; edge < end; edge++){
		     if (color_array[col[edge]] == -1 && start!=end-1){
		        *stop = 1; 
				//determine if the vertex value is the maximum/minimum in the neighborhood
		        if(node_value[col[edge]] > maximum)
		  	       maximum = node_value[col[edge]];
                if(node_value[col[edge]] < minimum)
                   minimum = node_value[col[edge]];
		     }
	      }
		  //assign the maximum/miminum value to max/min array
	      max_d[tid] = maximum;
          min_d[tid] = minimum;
    	}
   }
}

/**
 * @brief   color kernel 2
 * @param   node_value  Vertex value array 
 * @param   color_array Color value array
 * @param   max_d       Max array
 * @param   min_d       Min array
 * @param   color       Current color label 
 * @param   num_nodes   Number of vertices
 * @param   num_edges   Number of edges
 */
__kernel  void color2( __global int *node_value,
                       __global int *color_array,
                       __global int *max_d,
                       __global int *min_d,
                         const  int color,
                         const  int num_nodes,
                         const  int num_edges){

      //get my workitem id
     int tid = get_global_id(0);

     if (tid < num_nodes){
         //if the vertex is still not colored         
	     if(color_array[tid] == -1){
           //assign a color
	       if (node_value[tid] >= max_d[tid])
		       color_array[tid] = color;
           if (node_value[tid] <= min_d[tid])
		       color_array[tid] = color+1;
        }
    }

}

/**
 * @brief   init kernel 
 * @param   max_d       Max array
 * @param   min_d       Min array
 * @param   num_nodes   Number of vertices
 */
__kernel  void  ini(  __global int *max_d,
                      __global int *min_d,
                         const int  num_nodes){

    //get my workitem id
    int tid = get_global_id(0);
    
	//initialize max: -1 and min: Big_num
    if (tid < num_nodes){
        max_d[tid] = -1;
        min_d[tid] = BIG_NUM;
    }

}






