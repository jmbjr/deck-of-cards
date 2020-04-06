#!/bin/sh

echo "Delete existing pngs?"
read run_delete

echo "Run NanDeck?"
read run_nandeck

echo "scp data to remote?"
read run_scp

#NOTES:
#1. I've only run this using git-bash on windows. Should work with any bash-compatible terminal (adjust paths as needed)
#2. edit the lines below to customize script for your use
#3. option to "scp data to remote" requires access to a remote server that you can scp/ssh to. if you don't have access to that, just answer 'n' to this option

#EDIT THESE LINES

#remote=name of remote server set up in your .ssh/config file
#nandeck=path to your nanDECK executable
#local=path to your local Tabletop Simulator games folder. if you don't have Tabletop Simulator, set this to a dummy path (ToDo handle this better)
#ttsdir=output folder where output pngs will be created. you will have to ensure your decks actually use this directory (in decks-common.nde).
#savedir=output folder where TTS save files are located. you will need to manually keep your tts .json save file updated yourself. this script simply copies it locally to your tabletop simulator folder and uploads it to your remote.

remote="kvm"
nandeck="/d/dev/nandeck/nandeck_1_23_beta1/nanDECK.exe"
local="/d/Users/John/Documents/My Games/Tabletop Simulator"
ttsdir="./tts/"
savedir="./save/"
htmlfile="${ttsdir}/index.html"

#set up index.html file
echo "<HTML>" > ${htmlfile}
echo "<BODY text=#000000 link=#FF0000 bgColor=#9BB4B8><P align=center>" >> ${htmlfile}
echo "<font size=+2>Decks</font>" >> ${htmlfile}

echo "<br>" >> ${htmlfile}

echo "--------------------" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
echo "Delete existing pngs? = ${run_delete}" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
echo "Run NanDeck? = ${run_nandeck}" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
echo "scp data to remote? = ${run_scp}" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}

echo "NANDECK BUILD SCRIPT" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
date  | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
echo "--------------------" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}

#delete existing pngs
if ls ${ttsdir}/*.png 1> /dev/null 2>&1; then
  if [ "${run_delete}" == "y" ];then
    echo "REMOVING EXISTING *.PNG FILES FROM ${ttsdir} DIRECTORY!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    ls -l ${ttsdir}/*.png
    rm ${ttsdir}/*.png
    echo "PNG FILES DELETED!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
  else
    echo "SKIPPING DELETING PNG FILES" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
  fi
else
  echo "NO PNG FILES IN ${ttsdir}" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
fi

#build decks.
if [ "${run_nandeck}" == "y" ];then
  echo "BUIDLING DECKS!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
  ls -l *.nde
  for deck in *.nde
  do
    deckname="${deck%.*}"
    echo "BUILDING $deckname" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    $nandeck $deck //exec
    if ls ${ttsdir}/$deckname.png 1> /dev/null 2>&1; then
      echo "$deckname SUCCESSFULLY BUILT!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
      echo "<br><img src=\"$deckname.png\" alt=\"$deckname\" height="70%">" >> ${htmlfile} && echo "<br>" >> ${htmlfile}
    else
      echo "$deckname FAILED TO BUILD!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    fi
    echo "<br>" >> ${htmlfile}
  done
else
  echo "SKIPPING RUNNING NANDECK" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
fi

if [ "${run_scp}" == "y" ]; then
  #push to remote
  remotedir=basic-deck

  if ls ${ttsdir}/*.png 1> /dev/null 2>&1; then
    echo "COPYING FILES TO REMOTE SERVER!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    ls -l ${ttsdir}/*.png
    echo "REMOTE= $remote" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    
    ssh "${remote}"  'mkdir -p basic-deck/img && mkdir -p basic-deck/saves && rm basic-deck/img/*.png && rm basic-deck/saves/*.json'
    scp ${ttsdir}/*.png  "${remote}":${remotedir}/img/
    scp ${htmlfile}  "${remote}":${remotedir}/img/
    scp ${savedir}/*.json "${remote}":${remotedir}/saves/
  
    #clear local cache
    for localstring in basicdeck kidsfundeck backpng
    do
      if ls "${local}"/Mods/Images/*${localstring}*.png 1> /dev/null 2>&1; then
        echo "DELETING LOCAL CACHE" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
        ls -l "${local}"/Mods/Images/*${localstring}*.png
        rm "${local}"/Mods/Images/*${localstring}*.png
      else
        echo "NO LOCAL FILES TO DELETE!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
      fi
    done
    
    #install current save file to Save folder
    cp ${savedir}/*.json "${local}"/Saves/Chest
  else
    echo "NO PNG IMAGES FOUND IN CURRENT DIRECTORY!" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
    ls -l
  fi
else
  echo "SKIPPING SCPing FILES TO REMOTE" | tee -a ${htmlfile} && echo "<br>" >> ${htmlfile}
fi

echo "</BODY>" >> ${htmlfile}
echo "</HTML>" >> ${htmlfile}
