/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package paz.servlets;

import java.util.*;

/**
 *
 * @author Max
 */
public class CommentManager {

    private static final Map<String, List<String>> comments = new HashMap<String, List<String>>();

    public static List<String> getComments(String name) {
        if(!comments.containsKey(name)){
            return new ArrayList<String>();
        }
        return comments.get(name);
    }

    public static void addComment(String name, String msg) {
        List<String> msgs = comments.get(name);
        if (msgs == null) {
            msgs = new ArrayList<String>();
            comments.put(name, msgs);
        }
        msgs.add(msg);
    }

}
