/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package paz.servlets;

import java.io.IOException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 *
 * @author Max
 */
public class LoadComment extends HttpServlet{
    
    public void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException{
        String cityName = req.getParameter("city_name").toString();
        StringBuilder response = new StringBuilder("{ \"messages\": [");
        for(String msg: CommentManager.getComments(cityName)){
            response.append('"').append(msg).append("\",");
        }
        if(!CommentManager.getComments(cityName).isEmpty()){
        response.deleteCharAt(response.length()-1);
            
        }
        response.append("]}");
        
        resp.setContentType("application/json");
        resp.getWriter().write(response.toString());
    }
    
    public void doPost(HttpServletRequest req, HttpServletResponse resp){
        CommentManager.addComment(req.getParameter("city_name").toString(), req.getParameter("comment").toString());
    }
    
}
