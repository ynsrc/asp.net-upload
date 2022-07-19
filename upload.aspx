<%@ Page Language="C#" Debug="true" %>
<%
    const string PASSWORD = "your-password";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<title>File Upload</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width" />
<meta charset="utf-8" />
<style type="text/css">
    a { text-decoration: none; color: #0000ff; }
    a:hover { color: #ff0000; }
    body { padding-top: 2%; font-size: 14pt; }
    table { width: 100%; }
    table tr { border: solid 1px #222; }
    table th { text-align: left; padding-bottom: 3px; border-bottom: solid 2px #555; }
    table td { padding: 3px; }
    fieldset { border-radius: 5px; padding: 10px; border: solid 1px #060 }
    fieldset legend { padding: 0 10px; font-weight: bold; font-size: 16pt; }
    p.failure { color: #f00; font-weight: bold; }
    div.divider { padding: 10px 0; }
    h2.title { text-align: center; }
    h2.title a { color: #000; }
    h2.title a:hover { color: #f00; }
    .left-aligned { float: left; }
    .right-aligned { float: right; }
    .text-left { text-align: left; }
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .clear { clear: both; }
    input[type="checkbox"] { margin: 10px; }
    @media (min-width: 1200px) {
        body { margin: 0 auto; width: 800px; }
    }
</style>
</head>
<body>
<h2 class="title"><a href="<%=Request.Url%>">File Manager</a></h2>
<form method="post" enctype="multipart/form-data">
<fieldset class="text-center">
<legend class="text-left">File Upload</legend>
<p><input type="file" name="file[]" multiple /></p>
<p><input type="password" name="password" placeholder="Password" /> <input type="submit" name="upload" value="Upload Files" /></p>
<%
    if (Request.Files.Count > 0)
    {
        if (Request["password"] != PASSWORD)
        {
            Response.Write("<p class=\"failure\">Password was wrong!</p>");
        }
        else if (!string.IsNullOrEmpty(Request.Files[0].FileName))
        {
            for (int i = 0; i < Request.Files.Count; i++)
            {
                HttpPostedFile file = Request.Files[i];

                string filePath = Server.MapPath("uploads/" + file.FileName);
                string extension = System.IO.Path.GetExtension(file.FileName);

                if (extension == ".aspx" || extension == ".asax" || filePath == Server.MapPath("web.config"))
                {
                    Response.Write("<p class=\"failure\">Skipped illegal file type: " + file.FileName + "</p>");
                    continue;
                }

                try
                {
                    file.SaveAs(filePath);
                    string url = Server.UrlEncode("uploads/" + file.FileName);
                    Response.Write("<p><a href=\"/" + url + "\">" + file.FileName + "</a> uploaded successfully.</p>");
                }
                catch (Exception ex)
                {
                    Response.Write("<p>Upload Error: " + file.FileName + "!</p>");
                    Response.Write("<p>Message: " + ex.Message + "</p>");
                }
            }
        }
        else
        {
            Response.Write("<p class=\"failure\">No file selected!</p>");
        }
    }
%>
</fieldset>
</form>
<div class="divider"></div>
<form method="post">
<fieldset class="text-center">
<legend class="text-right">File Operations</legend>
<input type="password" name="password" placeholder="Password" />
<input type="submit" name="delete" value="Delete Selected Files" />
<%
    if (Request["delete"] != null)
    {
        if (Request["password"] != PASSWORD)
        {
            Response.Write("<p class=\"failure\">Password was wrong!</p>");
        }
        else
        {
            foreach (string selection in Request.Form.GetValues("selection[]"))
            {
                string filePath = Server.MapPath(selection);
                string extension = System.IO.Path.GetExtension(filePath);

                if (filePath == Server.MapPath("web.config") || extension == ".aspx")
                    continue;

                if (System.IO.File.Exists(filePath))
                {
                    try
                    {
                        System.IO.File.Delete(filePath);
                        Response.Write("<p>" + selection + " deleted successfully.</p>");
                    }
                    catch
                    {
                        Response.Write("<p class=\".failure\">Delete error: " + selection + "</p>");
                    }
                }
                else if (System.IO.Directory.Exists(filePath))
                {
                    try
                    {
                        System.IO.Directory.Delete(filePath, true);
                        Response.Write("<p>" + selection + "/ deleted successfully.</p>");
                    }
                    catch
                    {
                        Response.Write("<p class=\".failure\">Delete error: " + selection + "</p>");
                    }
                }
            }
        }
    }
%>
</fieldset>
<div class="divider"></div>
<fieldset>
<legend>Files</legend>
<%
    string path = Request.QueryString["path"];

    if (!string.IsNullOrEmpty(path))
    {
        try
        {
            path = System.Text.Encoding.UTF8.GetString(System.Convert.FromBase64String(path));
        }
        catch
        {
            path = "/uploads";
        }
    } else
    {
        path = "/uploads";
    }

    path = Server.MapPath(path);
    string basePath = Server.MapPath("/");

    string[] subEntries = System.IO.Directory.GetFileSystemEntries(path);

    if (subEntries.Length > 0)
    {
        
        Response.Write("<div class=\"divider\"></div>");

        Response.Write("<table>");
        Response.Write("<tr><th width=\"30\">Select</th><th>File Name</th></tr>");
    }
    else
    {
        Response.Write("<p>Folder is empty.</p>");
    }

    foreach (string fileName in subEntries)
    {
        string name = fileName.Replace(basePath, "");

        if (name == "web.config" || name == "aspnet_client" || System.IO.Path.GetExtension(name) == ".aspx")
            continue;

        if (System.IO.File.Exists(fileName))
        {
            Response.Write("<tr>");
            Response.Write("<td><input type=\"checkbox\" name=\"selection[]\" value=\"" + name + "\" /></td>");
            Response.Write("<td><a target=\"_blank\" href=\"" + name + "\">" + name + "</a></td>");
            Response.Write("</tr>");
        }
        else if (System.IO.Directory.Exists(fileName))
        {
            string hash = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(name));

            Response.Write("<tr>");
            Response.Write("<td><input type=\"checkbox\" name=\"selection[]\" value=\"" + name + "\" /></td>");
            Response.Write("<td><a href=\"/?path=" + hash + "\">" + name + "/</a></td>");
            Response.Write("</tr>");
        }
    }

    if (subEntries.Length > 0)
    {
        Response.Write("</table>");
    }
%>
</fieldset>
</form>
</body>
</html>
