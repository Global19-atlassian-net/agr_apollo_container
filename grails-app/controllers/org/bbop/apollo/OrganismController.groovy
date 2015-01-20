package org.bbop.apollo

import grails.converters.JSON
import org.codehaus.groovy.grails.web.json.JSONObject

import static org.springframework.http.HttpStatus.*
import grails.transaction.Transactional

@Transactional(readOnly = true)
class OrganismController {

    static allowedMethods = [save: "POST", update: "PUT", delete: "DELETE"]

    def index(Integer max) {
        params.max = Math.min(max ?: 10, 100)
        respond Organism.list(params), model: [organismInstanceCount: Organism.count()]
    }

    def list(Integer max) {
        forward action: "index"
    }

    def featureCountForOrganism(Organism organism) {

    }

    def show(Organism organismInstance) {
        respond organismInstance
    }

    def create() {
        respond new Organism(params)
    }

    @Transactional
    def save(Organism organismInstance) {
        if (organismInstance == null) {
            notFound()
            return
        }

        if (organismInstance.hasErrors()) {
            respond organismInstance.errors, view: 'create'
            return
        }

        organismInstance.save flush: true, failOnError: true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.created.message', args: [message(code: 'organism.label', default: 'Organism'), organismInstance.id])
                redirect organismInstance
            }
            '*' { respond organismInstance, [status: CREATED] }
        }
    }

    def edit(Organism organismInstance) {
        respond organismInstance
    }

    @Transactional
    def updateOrganismInfo() {
        println "updating organism info ${params}"
        println "updating feature ${params.data}"
//                        {"data":{"id":"14", "name":"Honey Bee7", "directory":"/opt/another.apollo/jbrowse/data"}}
        def organismJson = JSON.parse(params.data.toString()) as JSONObject
        println "jsonObject ${organismJson}"
        Organism organism = Organism.findById(organismJson.id)
        println "found an orgnaism ${organism}"
        if (organism) {
            organism.commonName = organismJson.name
            organism.directory = organismJson.directory
            organism.save(flush: true, insert: false, failOnError: true)
            render { text: 'updated' } as JSON
        } else {
            println "organism not found ${organismJson}"
            render { text: 'NOT updated' } as JSON
        }
    }

    @Transactional
    def changeOrganism(String id) {
        println "changing organism ${params}"
        JSONObject dataObject = JSON.parse(params.data)
        String organismId = dataObject.organismId
        println "organismId ${organismId}"
        Organism organism = Organism.findById(organismId as Long)
        if (organism) {
            println "found the organism ${organism}"
            // make not a magic string
            request.session.setAttribute("organismJBrowseDirectory", organism.directory)
//            request.session.setAttribute("organismJBrowseDirectory",organism.directory)
        } else {
            println "not found organism "
        }

        println "updating organism "
        println params.data
        render { text: 'changed' } as JSON
    }

    @Transactional
    def update(Organism organismInstance) {
        if (organismInstance == null) {
            notFound()
            return
        }

        if (organismInstance.hasErrors()) {
            respond organismInstance.errors, view: 'edit'
            return
        }

        organismInstance.save flush: true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.updated.message', args: [message(code: 'Organism.label', default: 'Organism'), organismInstance.id])
                redirect organismInstance
            }
            '*' { respond organismInstance, [status: OK] }
        }
    }

    @Transactional
    def delete(Organism organismInstance) {

        if (organismInstance == null) {
            notFound()
            return
        }

        organismInstance.delete flush: true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.deleted.message', args: [message(code: 'Organism.label', default: 'Organism'), organismInstance.id])
                redirect action: "index", method: "GET"
            }
            '*' { render status: NO_CONTENT }
        }
    }

    def findAllOrganisms() {
        println "finding all organisms: ${Organism.count}"
        render Organism.listOrderByCommonName() as JSON
    }

    protected void notFound() {
        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.not.found.message', args: [message(code: 'organism.label', default: 'Organism'), params.id])
                redirect action: "index", method: "GET"
            }
            '*' { render status: NOT_FOUND }
        }
    }

}
